SCRIPT_VERSION=3.1.4
CERT_VERSION=21.0.2

CP4BA_AUTO_NAMESPACE=cp4ba
CP4BA_AUTO_CLUSTER_USER="IAM#boyerje@us.ibm.com"

echo "##### 1- create user $CP4BA_AUTO_CLUSTER_USER"
htpasswd -c -B -b users.htpasswd $CP4BA_AUTO_CLUSTER_USER $CP4BA_AUTO_CLUSTER_USER
oc create secret generic htpass-secret --from-file=htpasswd=./users.htpasswd -n openshift-config
oc apply -f bootstrap/identityProvider.yaml
oc adm policy add-cluster-role-to-user cluster-admin $CP4BA_AUTO_CLUSTER_USER

echo "##### 2- Deploy LDAP in openldap project"
oc apply -k instances/openLDAP

echo "##### 3- get automation configuration"
curl -o ./assets/ibm-cp-automation-${SCRIPT_VERSION}.tgz -LJO https://github.com/IBM/cloud-pak/raw/master/repo/case/ibm-cp-automation/${SCRIPT_VERSION}/ibm-cp-automation-${SCRIPT_VERSION}.tgz
tar -xvzf ./assets/ibm-cp-automation-${SCRIPT_VERSION}.tgz -C ./assets
tar -xvzf ./assets/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-k8s-${CERT_VERSION}.tar -C ./assets/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs

sed -i '' 's/<NAMESPACE>/'"${CP4BA_AUTO_NAMESPACE}"'/' ./assets/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/descriptors/cluster_role_binding.yaml

echo "##### 4- create project ${CP4BA_AUTO_NAMESPACE}"
oc create namespace ${CP4BA_AUTO_NAMESPACE}
oc project ${CP4BA_AUTO_NAMESPACE}

oc apply -f bootstrap/service-account-for-demo.yaml -n ${CP4BA_AUTO_NAMESPACE}
oc adm policy add-scc-to-user privileged -z ibm-cp4ba-privileged -n ${CP4BA_AUTO_NAMESPACE}
oc adm policy add-scc-to-user anyuid -z ibm-cp4ba-anyuid -n ${CP4BA_AUTO_NAMESPACE}

export ENTITLEMENT_KEY=`cat ./assets/entitlement_key.text`
export IBM_EMAIL=`cat ./assets/entitlement_key.text`

export CP4BA_AUTO_PLATFORM="ROKS"
export CP4BA_AUTO_DEPLOYMENT_TYPE="demo"
export CP4BA_AUTO_STORAGE_CLASS_FAST_ROKS="ibmc-file-gold-gid"
export CP4BA_AUTO_ENTITLEMENT_KEY=`cat ./assets/entitlement_key.text`

cd ./assets/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/scripts
./cp4a-clusteradmin-setup.sh
cd "$OLDPWD"