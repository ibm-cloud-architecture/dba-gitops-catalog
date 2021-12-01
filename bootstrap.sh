SCRIPT_VERSION=3.1.4
CERT_VERSION=21.0.2

CP4BA_AUTO_NAMESPACE=cp4ba
CP4BA_AUTO_CLUSTER_USER="IAM#boyerje@us.ibm.com"

# modify with care
export ENTITLEMENT_KEY=`cat ./assets/entitlement_key.text`
export IBM_EMAIL=`cat ./assets/entitlement_key.text`

export CP4BA_AUTO_PLATFORM="ROKS"
export CP4BA_AUTO_DEPLOYMENT_TYPE="demo"
export CP4BA_AUTO_STORAGE_CLASS_FAST_ROKS="ibmc-file-gold-gid"
export CP4BA_AUTO_ENTITLEMENT_KEY=`cat ./assets/entitlement_key.text`

echo "Define IBM catalogs"
oc apply -f ibm-catalog/catalog_source.yaml
oc apply -k ibm-cp4a-catalog/overlays


echo "Define base operators"
oc apply -k operators/openshift-gitops/overlays/stable
oc apply -k operators/openshift-pipelines/overlays/stable
oc apply -k operators/sealed-secrets/overlays/default
oc apply -k operators/cn-postgresql/overlays

echo "Get IBM CP automation configuration and scripts"
curl -o ./assets/ibm-cp-automation-${SCRIPT_VERSION}.tgz -LJO https://github.com/IBM/cloud-pak/raw/master/repo/case/ibm-cp-automation/${SCRIPT_VERSION}/ibm-cp-automation-${SCRIPT_VERSION}.tgz
tar -xvzf ./assets/ibm-cp-automation-${SCRIPT_VERSION}.tgz -C ./assets
tar -xvzf ./assets/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-k8s-${CERT_VERSION}.tar -C ./assets/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs

sed -i '' 's/<NAMESPACE>/'"${CP4BA_AUTO_NAMESPACE}"'/' ./assets/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/descriptors/cluster_role_binding.yaml

echo "Create OCP project named: ${CP4BA_AUTO_NAMESPACE}"
oc create namespace ${CP4BA_AUTO_NAMESPACE}
oc project ${CP4BA_AUTO_NAMESPACE}

oc apply -f bootstrap/service-account-for-demo.yaml -n ${CP4BA_AUTO_NAMESPACE}
oc adm policy add-scc-to-user privileged -z ibm-cp4ba-privileged -n ${CP4BA_AUTO_NAMESPACE}
oc adm policy add-scc-to-user anyuid -z ibm-cp4ba-anyuid -n ${CP4BA_AUTO_NAMESPACE}


cd ./assets/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/scripts
./cp4a-clusteradmin-setup.sh

echo "Define Argocd projects"
oc apply -f bootstrap/argocd/cp4a-argo-project.yaml
oc apply -f bootstrap/argocd/odm-argo-project.yaml
oc apply -f bootstrap/argocd/ads-argo-project.yaml

echo "Start one of the main ArgonCD app depending of your need"
echo "oc apply -k config/argocd/cp4a"
echo "oc apply -k config/argocd/odm"
echo "oc apply -k config/argocd/ads"