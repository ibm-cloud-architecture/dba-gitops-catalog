# Deploy ADS to OpenShift

## Environment

1. Append local public key to server ~/.ssh/authorized_keys

  ```sh
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  ```

2. Install tmux, podman, httpd-tools, unzip on your workstation if not already there

3. Create htpasswd credentials file, secret

  ```sh
  htpasswd -c -B -b users.htpasswd OPENSHIFT_USER OPENSHIFT_USER_PASSWORD

  oc create secret generic htpass-secret --from-file=htpasswd=users.htpasswd -n openshift-config
  ```

4. Add identity provider to OpenShift

  Create yaml file:

  ```yaml
  apiVersion: config.openshift.io/v1
  kind: OAuth
  metadata:
  name: cluster
  spec:
  identityProviders:
  - name: local
      mappingMethod: claim
      type: HTPasswd
      htpasswd:
      fileData:
          name: htpass-secret
  ```
   
   Then do: 

  ```sh
  oc apply -f identityProvider.yaml
  oc adm policy add-cluster-role-to-user cluster-admin OPENSHIFT_USER
  ```

5. Add nfs folder to exports, get and configure provisioner, create storage class

  ```sh
  systemctl status nfs-server

  mkdir -p /ifs/kubernetes
  chmod -R 777 /ifs/kubernetes
  echo '/ifs/kubernetes  *(rw,sync,no_subtree_check,no_root_squash,insecure)' >> /etc/exports
  sudo exportfs -rv
  showmount -e

  wget https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/archive/refs/heads/master.zip

  oc adm policy add-scc-to-user hostmount-anyuid system:serviceaccount:default:nfs-client-provisioner

  oc apply -f nfs-subdir-external-provisioner-master/deploy/rbac.yaml
  
  ip a

  vi nfs-subdir-external-provisioner-master/deploy/deployment.yaml

  oc apply -f nfs-subdir-external-provisioner-master/deploy/deployment.yaml

  oc apply -f nfs-subdir-external-provisioner-master/deploy/class.yaml
  ```

## Cluster setup

1. Get Cloud Pak resources, run cluster setup script

  ```sh
  wget https://github.com/IBM/cloud-pak/raw/master/repo/case/ibm-cp-automation/3.1.3/ibm-cp-automation-3.1.3.tgz

  tar xvf ./ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-k8s-21.0.2.tar

  oc new-project cp4ba

  ./cert-kubernetes/scripts/cp4a-clusteradmin-setup.sh
  ```

## Configure dependencies

1. Create LDAP secret, OpenLDAP deployment and a service

  ```sh
  oc create secret generic openldap --from-literal=adminpassword=adminpassword --from-literal=users=user01,user02,cpadmin --from-literal=passwords=password01,password02,password
  ```

  ```yaml
  apiVersion:  apps/v1
  kind: Deployment
  metadata:
  name: openldap
  labels:
      app.kubernetes.io/name: openldap
  spec:
  selector:
      matchLabels:
      app.kubernetes.io/name: openldap
  replicas: 1
  template:
      metadata:
      labels:
          app.kubernetes.io/name: openldap
      spec:
      containers:
          - name: openldap
          image: docker.io/bitnami/openldap:latest
          imagePullPolicy: "Always"
          env:
              - name: LDAP_ADMIN_USERNAME
                value: "admin"
              - name: LDAP_ADMIN_PASSWORD
                valueFrom:
                  secretKeyRef:
                  key: adminpassword
                  name: openldap
              - name: LDAP_USERS
                valueFrom:
                  secretKeyRef:
                  key: users
                  name: openldap
              - name: LDAP_PASSWORDS
                valueFrom:
                  secretKeyRef:
                  key: passwords
                  name: openldap
          ports:
              - name: tcp-ldap
                containerPort: 1389
  ```

  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
  name: openldap
  labels:
      app.kubernetes.io/name: openldap
  spec:
  type: ClusterIP
  ports:
      - name: tcp-ldap
      port: 1389
      targetPort: tcp-ldap
  selector:
      app.kubernetes.io/name: openldap
  ```

  Test it:

  ```sh
  oc rsh $(oc get po -o name | grep ldap)

  ldapsearch -x -H ldap://localhost:1389 dc=example,dc=org -D "cn=admin,dc=example,dc=org" -w adminpassword
  ```

2. Download JDBC drivers to operator pod, create super user

  ```sh
  oc rsh $(oc get po -o name | grep 'cp4a-operator')
  mkdir /opt/ansible/share/jdbc/postgresql -p && cd "$_"

  curl https://jdbc.postgresql.org/download/postgresql-42.3.0.jar -O
  ```

3. Open remote shell to database pod and create super user

  ```sh
  oc rsh DATABASE_POD_NAME
  psql -U postgres
  ```

  ```SQL
  CREATE ROLE cpadmin PASSWORD 'password' SUPERUSER CREATEDB CREATEROLE INHERIT LOGIN;
  ```

3. Create UMS database

  ```SQL
  CREATE DATABASE umsdb OWNER cpadmin TEMPLATE template0 ENCODING UTF8;

  GRANT ALL PRIVILEGES ON DATABASE umsdb TO cpadmin;
  ```

4. Create ICN/BAN database

  ```SQL
  CREATE DATABASE os1db OWNER cpadmin TEMPLATE template0 ENCODING UTF8;

  REVOKE CONNECT ON DATABASE os1db FROM public;

  GRANT all privileges ON DATABASE os1db TO cpadmin;

  GRANT connect, temp, create ON DATABASE os1db TO cpadmin;

  CREATE TABLESPACE os1db_tbs OWNER cpadmin LOCATION '/var/lib/postgresql/data/pgdata';

  GRANT CREATE ON TABLESPACE os1db_tbs TO cpadmin;
  ```

5. Create Playback Server Engine database

  ```SQL
  CREATE USER aeadmin WITH PASSWORD 'password';

  CREATE DATABASE appengdb OWNER aeadmin TEMPLATE template0 ENCODING UTF8;

  GRANT ALL privileges ON DATABASE appengdb TO aeadmin;
  ```

6. Create BAS database

  ```SQL
  CREATE ROLE basadmin PASSWORD 'password' SUPERUSER CREATEDB CREATEROLE INHERIT LOGIN;

  CREATE DATABASE basdb WITH OWNER basadmin TEMPLATE template0 ENCODING UTF8;

  GRANT ALL privileges ON DATABASE basdb TO basadmin;

  \c basdb

  SET ROLE basadmin;

  CREATE SCHEMA IF NOT EXISTS basadmin AUTHORIZATION basadmin;
  ```

## Create secrets:

1. UMS

  ```yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: ibm-dba-ums-secret
  type: Opaque
  stringData:
    adminUser: "umsadmin"
    adminPassword: "password"
    oauthDBUser: "cpadmin"
    oauthDBPassword: "password"
    tsDBUser: "cpadmin"
    tsDBPassword: "password"
  ```

2. Playback Server Engine

  ```yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: playback-server-admin-secret
  type: Opaque
  stringData:
    AE_DATABASE_USER: "aeadmin"
    AE_DATABASE_PWD: "password"
  ```

3. BAS
  ```yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: icp4adeploy-bas-admin-secret
  type: Opaque
  stringData:
      dbUsername: "basadmin"
      dbPassword: "password"
  ```

## Appendix

Snapshot of new deployment:

[root@api.ads-test.cp.fyre.ibm.com ~]# oc get csv
NAME                                    DISPLAY                                      VERSION   REPLACES                              PHASE
cloud-native-postgresql.v1.9.2          Cloud Native PostgreSQL                      1.9.2                                           Succeeded
ibm-automation-core.v1.2.0              IBM Automation Foundation Core               1.2.0                                           Succeeded
ibm-automation-elastic.v1.2.0           IBM Elastic                                  1.2.0                                           Succeeded
ibm-automation-eventprocessing.v1.2.0   IBM Automation Foundation Event Processing   1.2.0                                           Succeeded
ibm-automation-flink.v1.2.0             IBM Automation Foundation Flink              1.2.0                                           Succeeded
ibm-automation.v1.2.0                   IBM Automation Foundation                    1.2.0                                           Succeeded
ibm-common-service-operator.v3.12.0     IBM Cloud Pak foundational services          3.12.0    ibm-common-service-operator.v3.11.0   Succeeded
ibm-cp4a-operator.v21.2.3               IBM Cloud Pak for Business Automation        21.2.3    ibm-cp4a-operator.v21.2.2             Succeeded

[root@api.ads-test.cp.fyre.ibm.com ~]# oc get csv -n ibm-common-services
NAME                                           DISPLAY                                VERSION   REPLACES                                      PHASE
cloud-native-postgresql.v1.9.2                 Cloud Native PostgreSQL                1.9.2                                                   Succeeded
ibm-cert-manager-operator.v3.14.0              IBM Cert Manager                       3.14.0    ibm-cert-manager-operator.v3.13.0             Succeeded
ibm-common-service-operator.v3.12.0            IBM Cloud Pak foundational services    3.12.0    ibm-common-service-operator.v3.11.0           Succeeded
ibm-licensing-operator.v1.9.0                  IBM Licensing Operator                 1.9.0     ibm-licensing-operator.v1.8.0                 Succeeded
ibm-namespace-scope-operator.v1.6.0            IBM NamespaceScope Operator            1.6.0     ibm-namespace-scope-operator.v1.5.0           Succeeded
operand-deployment-lifecycle-manager.v1.10.0   Operand Deployment Lifecycle Manager   1.10.0    operand-deployment-lifecycle-manager.v1.9.0   Succeeded


[root@api.ads-test.cp.fyre.ibm.com ~]# oc get jobs -n ibm-common-services
NAME                       COMPLETIONS   DURATION   AGE
iam-onboarding             0/1           47s        47s
oidc-client-registration   0/1           46s        46s
security-onboarding        0/1           48s        48s
setup-job                  1/1           7s         115s

## Bibliography:

*Preparing:*

Resources: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=deployments-preparing-enterprise-deployment

Cluster: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=cluster-setting-up-by-running-script

Capabilities: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-enterprise-deployments

LDAP: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=parameters-ldap-configuration

UMS DB: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=database-preparing-postgresql

BAN DB: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=navigator-preparing-database

BAS/Playback Server Engine DB: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=databases-creating-postgresql-database

Secrets: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=authoring-creating-secrets-protect-sensitive-configuration-data

*Configuration:*

UMS: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-user-management-services

BAS: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-business-automation-studio

ADS: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-automation-decision-services

*Parameters*:

UMS: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=parameters-ums

BAS: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=parameters-business-automation-studio

ADS: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=parameters-automation-decision-services
