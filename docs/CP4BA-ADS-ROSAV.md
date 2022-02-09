# **IBM Cloud Pak for Business Automation** deployment on AWS  Managed RedHat OpenShift ROSA

## Overview

This document provides step-by-step instructions for deploying a production instance of IBM Automation Decision Services (ADS) on Cloud Pak for Business Automation on AWS ROSA (Managed RedHat OpenShift) . 
This deployment spans into a virtual private cloud (VPC) across 3 Availability Zones for high availability. 

This guide is for those who looking to privilege managed services including ROSA, Document, 
AWS directory services. User should also be familiar with AWS and cloud concepts such as bastion hosts, 
security groups, Amazon Elastic Compute Cloud (Amazon EC2),

## IBM ADS On IBM cloud pak for Business Automation 

IBM Cloud Pak for Automation offers design, build, run, and automation services to rapidly scale your programs and fully execute and operationalize an automation strategy.

[IBM Cloud Paks](https://www.ibm.com/links?url=https%3A%2F%2Fgithub.com%2FIBM%2Fcloud-pak) meet standard 
criteria for packaging and deployment of containerized software with platform integrations. 
IBM Cloud Paks accelerate time to value, and improve enterprise readiness and business agility.

IBM Cloud Pak for Business Automation helps to automate business operations with an integrated 
platform of automation capabilities. The platform relies on Kubernetes, which is open source 
application container orchestration software that makes it easier to configure, deploy, and manage 
containerized applications. It is designed to help all types of projects small and large, 
improve employee productivity, and deliver better end-to-end customer journeys while you reduce 
the burden of governing your content and processes. It can increase your ability to scale and do 
more work faster and better.

Automation capabilities empower your business to work more effectively in the following cases:

* When your headcounts are static, but the workload must manage new applications or services, 
rising customer demand, or seasonal fluctuations.
* When you want to create enhanced and personalized customer experiences that increase loyalty 
by drawing insights instantly from multiple sources of information.
* When you need to scale operations to help maximize revenue and customer service.

IBM Cloud Pak for Business Automation offers a unified user experience for consistency across 
operations, reusable skills and assets that you can share between applications, and platform services 
that drive analytics and insight with operational intelligence. The platform can also coordinate its 
capabilities with your existing infrastructure. For example, content management for an insurance 
company’s case management needs. Content management can include searching files for relevant data, 
managing the business processes necessary for completing a claim, and providing decisions based on 
company policies.

The following diagram shows the capabilities of IBM Cloud Pak for Business Automation and the core program offerings that the platform provides.

<img src="images/Cp4BA.jpg"  style="zoom:50%;align:center" />

[IBM Automation Decision Services](https://www.ibm.com/automation/business-rules) (available as part of [IBM Cloud Pak for Automation](https://www.ibm.com/cloud/cloud-pak-for-automation)) 
helps business users make the business decisions through a simple interface that requires no coding. Because conditions evolve, business users can also quickly 
change the way decisions are made and stay aligned with important business requirements.

Decisions are made with well-known conditions and well-defined policies. But they increasingly require you have a view into the future. 
ADS makes the link between AI predictions and concrete decisions simple and actionable for workers without AI expertise. 

## AWS ROSA

[https://docs.aws.amazon.com/ROSA/latest/userguide/what-is-rosa.html](https://docs.aws.amazon.com/ROSA/latest/userguide/what-is-rosa.html) 

Red Hat OpenShift Service on AWS is a managed service that's available through the AWS Management Console. It helps Red Hat OpenShift users build, scale, and manage 
containerized applications on AWS. With ROSA, you can create Kubernetes clusters using Red Hat OpenShift APIs and tooling and have access to the full breadth and depth 
of AWS services. ROSA streamlines moving on-premises Red Hat OpenShift workloads to AWS, and offers tight integration with other AWS services. With ROSA, you can access 
Red Hat OpenShift licensing, billing, and support all directly through AWS.
There are no up-front costs required to use ROSA. You pay only for the container clusters and nodes that you use. With pay-as-you-go pricing, you don't have to 
worry about complex, multi-year contracts. This flexibility means that you can align your Red Hat OpenShift consumption in AWS with your business needs.


## Architecture 

The following diagrams depicts an on overview of deployment architecture span on 3 AZs 

<img src="images/arch1.png"  style="zoom:100%;align:center" />

The below diagram details the setups of components per subnet

<img src="images/arch2.png" alt="arch2" style="zoom:100%;align:center"/>

The Quick Start sets up the following: 

* A highly available architecture that spans multiple Availability Zones. 
* A VPC configured with public and private subnets according to AWS best practices, to provide you with your own virtual network on AWS. 

**In the public subnet** 

* A Linux bastion host to allow inbound Secure Shell (SSH) access to EC2 instances in public and private subnets. 
* A Microsoft Windows servers hosting administration tools for AWS directory services, Document DB and Db2 installed on EC2 

**In the private subnet**  

* ROSA cluster hosing Cloud Pak for Business automation, ADS and business automation Studio 
* AWS directory Service deployed in two availability zone for redundancy.
* AWS document DB providing Mongo DB database  deployed in two availability zone for redundancy.
* IBM DB2 Database installed on EC2 and deployed in two availability zone for redundancy.

### Planning the deployment

### Preparing the pre-reqs

#### Installing the ROSA cluster 

The following link provides the installation guide of ROSA as provided by AWS:

https://docs.aws.amazon.com/ROSA/latest/userguide/ROSA-guide.pdf

#### ROSA Pre-requisite management 

The link below provides the link for AWS resources pre-reqs cluster : 

https://docs.openshift.com/rosa/rosa_getting_started/rosa-aws-prereqs.html

Requirements for EC2 instance size should be customized based on your workload requirements.

In the case of this deployment sizing was based on the following estimations:

#####  **Cloud Pak for Business Automation operator minimum requirements:** 

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=pei-system-requirements#concept_dff_npf_pkb__table_operator

##### **Automation Decision Services default requirements**:

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=pei-system-requirements#concept_dff_npf_pkb__table_operator

The tables below present estimated requirement for ADS deployment based on this minimum capability  requirements as depicted in the above:

| Component         | CPU Request (m) | CPU Limit (m) | Memory Request (Mi) | Memory Limit (Mi) | Number of replicas | Pods are licensed for production/non-production |
| :---------------- | :-------------- | :------------ | :------------------ | :---------------- | :----------------- | :---------------------------------------------- |
| ibm-cp4a-operator | 500             | 1000          | 256                 | 1024              | 1                  | No                                              |



| Component                       | CPU Request (m)   | CPU Limit (m)       | Memory Request (Mi) | Memory Limit (Mi)   | Number of replicas                            | Pods are licensed for production/non-production |
| :------------------------------ | :---------------- | :------------------ | :------------------ | :------------------ | :-------------------------------------------- | :---------------------------------------------- |
| ads-runtime                     | 1000              | 2000                | 2048For 21.0.1 512  | 3072For 21.0.12048  | 2 - 5 with horizontal pod autoscaling enabled | Yes                                             |
| For 21.0.1 ads-embedded-runtime | 1000              | 2000                | 512                 | 2048                | 2                                             | Yes                                             |
| ads-credentials                 | 250For 21.0.1 500 | 500For 21.0.1 2000  | 800For 21.0.1 512   | 1536For 21.0.1 2048 | 2                                             | No                                              |
| ads-embedded-build              | 500               | 2000                | 1024                | 2048                | 2                                             | No                                              |
| ads-download                    | 100               | 300For 21.0.1 500   | 200                 | 200                 | 2                                             | No                                              |
| ads-front                       | 250For 21.0.1 500 | 500For 21.0.1 2000  | 256For 21.0.1 512   | 512For 21.0.1 2048  | 2                                             | No                                              |
| ads-gitservice                  | 500               | 1000For 21.0.1 2000 | 800For 21.0.1 512   | 1536For 21.0.1 2048 | 2                                             | No                                              |
| ads-parsing                     | 250For 21.0.1 500 | 1000For 21.0.1 2000 | 800For 21.0.1 512   | 1536For 21.0.1 2048 | 2                                             | No                                              |
| ads-restapi                     | 500               | 1000For 21.0.1 2000 | 800For 21.0.1 512   | 1536For 21.0.1 2048 | 2                                             | No                                              |
| ads-run                         | 500               | 1000For 21.0.1 2000 | 800For 21.0.1 512   | 1536For 21.0.1 2048 | 2                                             | No                                              |
| mongo                           | 500               | 1000                | 256                 | 1024                | 2                                             | No                                              |



**Note:** Automation Decision Services also creates some jobs that request 200m CPU and 256Mi Memory. The following jobs are created once at the beginning of the installation and do not last long:

* ads-ltpa-creation
* ads-runtime-bai-registration
* ads-runtime-ums-registration
* ads-ums-registration

The ads-rr-integration job is started every 15 minutes, and is also short-lived.

The diagram below presents needed EC2 resources based on the above sizing

<img src="images/ArchSizing.png" alt="ArchSizing" style="zoom:20%;align:center" />

Hence EC2 requirements are; 

* Three m5.xlarge (control plane nodes)
* Three m5.xlarge (infrastructure nodes)
* Three m5.4xlarge storage nodes 
* Two m5.4xlarge (worker nodes)

<img src="images/ArchSizing2.png" alt="ArchSizing2" style="zoom:80%;align:center" />

####  Installing the bastion host 

EC2 bastion host is strongly recommended to secure access during deployments and installation tasks 

The following link provides a guide to setup a bastion host:  

https://aws-quickstart.github.io/quickstart-linux-bastion/

#### Installing Active directory service

The following link provide step by step guide to instal AWS directory service (AWS Managed Microsoft AD):

https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_microsoft_ad.html?icmpid=docs_dirservices_console 

https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_getting_started_prereqs.html

 The service should be installed in the same VPC as ROSA and should have tow instance deployed in two subnets / Azs . 

####  Installing Document DB Service 

Automation Decision Services requires a MongoDB database. For this task , we will use Amazon Doucment DB. Amazon DocumentDB is a fully managed document database service that supports MongoDB workloads.

* The service should be installed in the same VPC as ROSA and should have tow instance deployed in two subnets / Azs .  

Below is a link providing steps by steps guide to step Document DB : 

https://docs.aws.amazon.com/documentdb/latest/developerguide/get-started-guide.html 

#### Preparing an Enterprise deployment for Cloud Pak for Business automation

The below link presents list of requirements that need to be checked and verified before initiating the installation. 

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=planning-enterprise-installation

 Make sure that you prepare your environment and install the necessary software before you go to the GitHub repositories to find resources to install the IBM certified software.

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=deployments-preparing-enterprise-deployment

 The client side requirements can be installed on the bastion hosts installed in step 3.1.2

PS : the following link provide access to access container software library : 

https://myibm.ibm.com/products-services/containerlibrary

Your entitlement key is required to avail access  

#### Preparing Capabilities for ADS and BAS on Cloud for Pak Business automation

Follow the guidance provided in the below links to prepare capabilities for UMS, ADS and BAS all required for a successful if installation 

 **UMS :** 

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-user-management-services

**ADS :** 

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-business-automation-studio 

**BAS :**

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-business-automation-studio

LDAP configuration 

 https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=parameters-ldap-configuration 

####  Installing Administration tools for Db2, Mongo and AD

The installation of the above three services provides you with a server side components, it is recommended to install Client administation tools to interact with these services , one of the options are : 

#### AWS directory Service (Managed Active Directory) Administration 

AWS provide a guide on managing AWS directory service 

https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_tutorial_test_lab_base.html

Step 3 in particular provides details on how to Deploy an EC2 instance to manage your AWS Managed Microsoft AD:

https://docs.aws.amazon.com/directoryservice/latest/admin-guide/microsoftadbasestep3.html

#### IBM Db2 Data Management Console

IBM® Db2 Data Management Console is an integrated database management tools platform that you can use to manage DB2® for Linux, UNIX, and Windows databases. It is simple to set up, easy to use, and enterprise ready with the ability to manage hundreds of databases. the tools is available to download from the link below 

https://www.ibm.com/docs/en/db2-data-mgr-console/3.1.x

##### **Connect to your Databases:**

##### **Db2** 

Create the connections using the connection console by indicating the connections settings to your schemas UMSDB, APPENG and BA Studio, for connections to work , 

*Please ensure that AWS EC2 security group is configured to allow incoming connections from your client machine 

| <img src="images/db2connect.png" alt="db2connect" style="zoom:20%;align:center" /> | <img src="images/db2connect2.png" alt="db2connect2" style="zoom:40%;align:center" /> |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

#### Mongo Compass as client tool for AWS Document DB

One of the options is to use Mongo Compass. Compass Visually explore your data. Run ad hoc queries in seconds. Interact with your data with full CRUD functionality. View and optimize your query performance. Available on Linux, Mac, or Windows. Compass empowers you to make smarter decisions about indexing, document validation, etc..

https://www.mongodb.com/products/compass

**Connect to your Mongo Databases:**

Create new connection from compass using the following parameters 

mongodb://***yourmongo:yourpasswod*@*yourMongoCluter***:27017/?authSource=admin&readPreference=primary&appname=MongoDB%20Compass&directConnection=true&ssl=false



*you may use the same Ec2 instance used to manage AD as both EC2 and Mongo are supposed to be located on the same VPC

*Please ensure that AWS EC2 security group is configured to allow incoming connections from your client machine 

## Installation Steps 

Connect to your bastion host 

Follow the instructions provided by the install guide available on : 

**https://github.com/icp4a/cert-kubernetes/blob/20.0.1/ADW/README_config.md**

- [Step 1: Create a namespace and get access to the container images](https://github.com/icp4a/cert-kubernetes/blob/20.0.1/platform/ocp/install.md#step-1-create-a-namespace-and-get-access-to-the-container-images)
- [Step 2: Prepare your environment for automation software](https://github.com/icp4a/cert-kubernetes/blob/20.0.1/platform/ocp/install.md#step-2-prepare-your-environment-for-automation-software)
- [Step 3: Create a shared PV and add the JDBC drivers](https://github.com/icp4a/cert-kubernetes/blob/20.0.1/platform/ocp/install.md#step-3-create-a-shared-pv-and-add-the-jdbc-drivers)
- [Step 4: Deploy the operator manifest files to your cluster](https://github.com/icp4a/cert-kubernetes/blob/20.0.1/platform/ocp/install.md#step-4-deploy-the-operator-manifest-files-to-your-cluster)
- [Step 5: Configure the software that you want to install](https://github.com/icp4a/cert-kubernetes/blob/20.0.1/platform/ocp/install.md#step-5-configure-the-software-that-you-want-to-install)
- [Step 6: Apply the custom resource](https://github.com/icp4a/cert-kubernetes/blob/20.0.1/platform/ocp/install.md#step-6-apply-the-custom-resource)
- [Step 7: Verify that the automation containers are running](https://github.com/icp4a/cert-kubernetes/blob/20.0.1/platform/ocp/install.md#step-7-verify-that-the-automation-containers-are-running)
- [Step 8: Complete some post-installation steps](https://github.com/icp4a/cert-kubernetes/blob/20.0.1/platform/ocp/install.md#step-8-complete-some-post-installation-steps)

## Verify CRD file 

cp4a-clusteradmin-setup.sh allows to generate and CRD Yaml file (ibm_cp4a_cr.yaml) generally located in s

**/youhomefollder/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/scripts/generated-cr**

#### Verify and complete ibm_cp4a_cr.yaml file:

##### Shared configuration 

Review the following paramters



> >
> > - ```
> >   ......
> >     
> >   - apiVersion: icp4a.ibm.com/v1
> >     kind: ICP4ACluster
> >     metadata:
> >     name: icp4adeploy
> >     labels:
> >       app.kubernetes.io/instance: ibm-dba
> >       app.kubernetes.io/managed-by: ibm-dba
> >       app.kubernetes.io/name: ibm-dba
> >       release: 21.0.1
> >     spec:
> >     
> >     ## CP4A application version
> >     
> >     appVersion: 21.0.1.1
> >     
> >     ## CP4A application version
> >     
> >     ## MUST exist, used to accept ibm license, valid value only can be "accept" 
> >     
> >     ibm_license: accept
> >     #################################################################################################################
> >     ######################################################################################################################
> >     shared_configuration:
> >       ....
> >       sc_deployment_license: "production"
> >       ......
> >       sc_image_repository: cp.icr.io
> >      ......
> >       root_ca_secret: icp4a-root-ca
> >      .....
> >       sc_deployment_patterns: "foundation,application,decisions_ads"
> >      ......
> >       sc_optional_components: "ads_designer,ads_runtime,app_designer"
> >      ....
> >      sc_deployment_type: "enterprise"
> >      ....
> >      sc_deployment_platform: "OCP"
> >      ...
> >      sc_deployment_hostname_suffix: "{{ meta.namespace }}.yourrosacluster"
> >      .....
> >       sc_ingress_enable: false
> >      ................
> >      storage_configuration:
> >         sc_slow_file_storage_classname: ocs-storagecluster-cephfs
> >         sc_medium_file_storage_classname: ocs-storagecluster-cephfs
> >         sc_fast_file_storage_classname: ocs-storagecluster-cephfs
> >      ....
> >      sc_content_initialization: false
> >       sc_cpe_limited_storage: false
> >       image_pull_secrets:
> >       - admin.registrykey
> >     
> >   ```
> >   
> >   

    #### LDAP configuration  (Assunimg no TLS )   
```
ldap_configuration:
...
lc_selected_ldap_type: "Microsoft Active Directory"
    ....
    **lc_ldap_server: "yourHostdomaine name or IP"**
   ....
   ldap_configuration:
    ...
    lc_selected_ldap_type: "Microsoft Active Directory"
    ...
    lc_ldap_server: 1yourHostdomaine name or IP"
    ....
    lc_ldap_port: "389 oor 636 if TLS"
    .....
    lc_bind_secret: ldap-bind-secret
    ...
    lc_ldap_base_dn: "your base DN"  # Example : DC=corp,DC=cp4a,DC=rosa
    ...
    lc_ldap_ssl_enabled: false #or true if enable 
    ....
  
    lc_ldap_user_name_attribute: "user:sAMAccountName"
    lc_ldap_user_display_name_attr: "sAMAccountName"
    lc_ldap_group_base_dn:  "your base DN"  # Example : DC=corp,DC=cp4a,DC=rosa 
    lc_ldap_group_name_attribute: "*:cn"
    lc_ldap_group_display_name_attr: "cn"
    lc_ldap_group_membership_search_filter: "(&(cn=%v)(objectcategory=group))"
    lc_ldap_group_member_id_map: "memberOf:member"
    ad:
      lc_ad_gc_host: ""
      lc_ad_gc_port: ""
      lc_user_filter: "(&(sAMAccountName=%v)(objectcategory=user))"
      lc_group_filter: "(&(cn=%v)(objectcategory=group))"
      # tds:
      #   lc_user_filter: "(&(cn=%v)(objectclass=person))"
      #   lc_group_filter: "(&(cn=%v)(|(objectclass=groupofnames)(objectclass=groupofuniquenames)(objectclass=groupofurls)))"
```

#### Databases Configuration 

```
datasource_configuration:
    dc_ssl_enabled: false
   ...
   dc_icn_datasource:
    dc_database_type: "db2
    database_servername: "your server domaine name or IP"
    database_port: "Database port"
    database_name: "ECMDS"
  dc_ums_datasource:
     dc_ums_oauth_type: "db2"
      dc_ums_oauth_host: "your server domaine name or IP"
      dc_ums_oauth_port: "Database port"
      dc_ums_oauth_name: "UMSDB"
      dc_ums_oauth_name: "UMSDB"
      dc_ums_oauth_schema: OAuthDBSchema
      dc_ums_oauth_ssl: false
      dc_ums_oauth_driverfiles: db2jcc4.jar, db2jcc_license_cu.jar
      dc_ums_oauth_alternate_ports: dc_ums_teamserver_type: "db2"
      dc_ums_teamserver_host: "your server domaine name or IP"
      dc_ums_teamserver_port: "50001"
      dc_ums_teamserver_name: "UMSDB"
      dc_ums_teamserver_ssl: false   
 #############################################################################

  ## This section contains the BAStudio component configurations              #
  #############################################################################
  bastudio_configuration:
    admin_secret_name: icp4adeploy-bas-admin-secret
    admin_user: "ldap user" # create a user in your ldap using AD admin tools
    database:
      host: "Server Domain name or IP"
      name: "BASDB"  #name of created schema during pre-reqs of DB2 install
      use_custom_jdbc_drivers: false  
      port: "DB port"
      type: db2
      ssl_enabled: false
   playback_server:
     admin_user:  "ldap user" # create a user in your ldap using AD admin tools
      use_custom_jdbc_drivers: false
      database:
        host: "Server Domain name or IP"
        name: "APPENG" #name of created schema during pre-reqs of DB2 install
        #Provide the database server port for playback application engine use
        port: "DB port"
       type: db2
        enable_ssl: false
        ########################################################################
  ########   IBM User and Group Management Service configuration  ########
  ########################################################################
  ums_configuration:
   application_engine_configuration:
     admin_user: " your ldap user"
     use_custom_jdbc_drivers: false
    oauth:
     autoscaling:
       enabled: false
       maxReplicas: 2
       minReplicas: 1
       replica_count: 1
    database:
      host: "your DB server "
      name: "APPENG"  #(name of schema created for UMS configuration)
      port: "your DB port"
      type: db2
```

####    IBM Business Automation Decision Services

    session:
          use_external_store: false
        redis:
          # Your external redis host/ip
          host:
          # Your external redis port
          port: '6379'
          # If your redis enabled TLS connection set this to true
          # You should add redis server CA certificate in tls_trust_list or trusted_certificate_list
          tls_enabled: false
      ########################################################################
      ########   IBM Business Automation Decision Services            ########
      ########################################################################
      ads_configuration:
        decision_designer:
          enabled: true
        decision_runtime:
          enabled: true
        mongo:
          admin_secret_name: ibm-dba-ads-mongo-secret
          ads-runtime:         
          decision_runtime_service:
          image:
            repository: "cp.icr.io/ads-runtime"
            tag: "21.0.1"
            autoscaling:
              enabled: true
              min_replicas: 3
              max_replicas: 3
              target_cpu_average_utilization: 160
            resources:
              limits:
                memory: "2Gi"
                cpu: "2000m"
              requests:
                memory: "512Mi"
                cpu: "1000m"
            repository: "cp.icr.io/ads-embedded-runtime"
            tag: "21.0.1"
            autoscaling:
              enabled: true
              min_replicas: 2
              max_replicas: 2
              target_cpu_average_utilization: 160
            resources:
              limits:
                memory: "2Gi"
                cpu: "2000m"
              requests:
                memory: "512Mi"
                cpu: "1000m"            
            To be Continued !!

#### Verify Secrets Structure

##### ldap-bind-secret

#### 

| ldapPassword | your ldap user password                                      |
| ------------ | ------------------------------------------------------------ |
| ldapUsername | DN tree to your users : Example : `CN=admincp4ba1,OU=Users,OU=cp4autoads,DC=corp,DC=cp4a,DC=rosa` |

##### **ibm-dba-ads-mongo-secret** 

| **gitMongoUri**     | mongodb://admin:pass@your  mongo cluster url:27017/ads-git?retryWrites=true&w=majority&authSource=admin |
| ------------------- | ------------------------------------------------------------ |
| **mongoHistoryUri** | mongodb://admin:pass@your  mongo cluster url:27017/ads-history?retryWrites=true&w=majority&authSource=admin |
| **mongoUri**        | mongodb://admin:pass@your  mongo cluster url:27017/ads?retryWrites=true&w=majority&authSource=admin |
| **runtimeMongoUri** | mongodb:// admin:pass@your  mongo cluster url:27017/ads-runtime?retryWrites=true&w=majority&authSource=admin |
| mongoPassword       | your mongo admin user password                               |
| mongoUser           | your mongo admin user name                                   |

##### icp4adeploy-bas-admin-secret

Two values need to be configured , other values will be generated :

| dbPassword | DB password (in case of D2)   |
| ---------- | ----------------------------- |
| dbUsername | Database name (in case of D2) |

## Troubleshootings

- https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=automation-troubleshooting

- [https://www.ibm.com/support/pages/mustgather-collecting-data-diagnose-issues-ibm-business-automation-studio#Config](https://www.ibm.com/support/pages/mustgather-collecting-data-diagnose-issues-ibm-business-automation-studio)

  


 

