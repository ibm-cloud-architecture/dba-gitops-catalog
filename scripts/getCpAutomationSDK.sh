function getCpAutomationSDG() {
    SCRIPT_VERSION=$1
    CERT_VERSION=$2
    echo "Get IBM CP automation configuration and scripts"
    curl -o ./assets/ibm-cp-automation-${SCRIPT_VERSION}.tgz -LJO https://github.com/IBM/cloud-pak/raw/master/repo/case/ibm-cp-automation/${SCRIPT_VERSION}/ibm-cp-automation-${SCRIPT_VERSION}.tgz
    tar -xvzf ./assets/ibm-cp-automation-${SCRIPT_VERSION}.tgz -C ./assets
    tar -xvzf ./assets/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-k8s-${CERT_VERSION}.tar -C ./assets/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs

}

getCpAutomationSDG 3.2.0 21.0.3