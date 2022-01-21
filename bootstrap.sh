SCRIPT_VERSION=3.2.0
CERT_VERSION=21.0.3

CP4BA_AUTO_NAMESPACE=cp4a
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
oc apply -k openshift-gitops/overlays/stable
#oc apply -k operators/openshift-pipelines/overlays/stable
oc apply -k sealed-secrets/overlays/default
oc apply -k cn-postgresql/overlays

echo "Get IBM CP automation configuration and scripts"
source scripts/getCpAutomationSDG
getCpAutomationSDG ${SCRIPT_VERSION} ${CERT_VERSION}

sed -i '' 's/<NAMESPACE>/'"${CP4BA_AUTO_NAMESPACE}"'/' ./assets/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/descriptors/cluster_role_binding.yaml

echo "Create OCP project named: ${CP4BA_AUTO_NAMESPACE}"
oc new-project ${CP4BA_AUTO_NAMESPACE}
oc project ${CP4BA_AUTO_NAMESPACE}

oc apply -f cp4ba-operator/service-accounts.yaml -n ${CP4BA_AUTO_NAMESPACE}
oc adm policy add-scc-to-user privileged -z ibm-cp4ba-privileged -n ${CP4BA_AUTO_NAMESPACE}
oc adm policy add-scc-to-user anyuid -z ibm-cp4ba-anyuid -n ${CP4BA_AUTO_NAMESPACE}

cd ./assets/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/scripts
./cp4a-clusteradmin-setup.sh
