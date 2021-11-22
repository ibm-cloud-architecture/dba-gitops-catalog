# Digital Business Automation Solution gitOps catalog

This GitOps Catalog includes [kustomize](http://kustomize.io) bases and overlays folders for a 
number of OpenShift operators needed 
to develop Digital Business Automation solution and services.

This project is using the same structure as introduced by Red Hat COP team in [this repository](https://github.com/redhat-cop/gitops-catalog).

## Pre-requisites

### Red Hat OpenShift  

Get a running OpenShift v4.7+ cluster with enough resources to deploy cloud pak for automation. 
A cluster will all capabilities need 11 nodes (see [system requirements](https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=pei-system-requirements)):

* Master (3 nodes): 4 vCPU and 8 Gi memory on each node.
* Worker (8 nodes): 16 vCPU and 32 Gi memory on each node.

### IBM Entitlement Key

The IBM Entitlement Key is required to pull IBM Cloud Pak specific container images from the IBM Entitled Registry. To get an entitlement key,

* Log in to MyIBM Container Software Library with an IBMid and password associated with the entitled software. See
[https://www.ibm.com/docs/en/cloud-paks/1.0?topic=clusters-obtaining-your-entitlement-key](https://www.ibm.com/docs/en/cloud-paks/1.0?topic=clusters-obtaining-your-entitlement-key) 

    1. Select the View library option to verify your entitlement(s).
    1. Select the Get entitlement key to retrieve the key, place it in a file called `./assets/entitlement_key.text`
    1. Enter the email address used to generate the entitlement key in a file called `./assets/ibm_email.text`
    
## Usage

Each catalog item has its own README.md for future instructions. Be sure to use the most recent `oc` CLI, 
see the OpenShift oc download page [here](https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/).

```sh
git clone https://github.com/ibm-cloud-architecture/dba-gitops-catalog.git
```

Be sure to start by adding IBM product catalog to OpenShift

```sh
oc apply -f ibm-catalog/catalog_source.yaml
```

  1. A Secret containing the entitlement key is created in the tools namespace.

        ```sh
        oc new-project cp4ba || true
        oc create secret docker-registry ibm-entitlement-key -n cp4ba \
        --docker-username=cp \
        --docker-password="<entitlement_key>" \
        --docker-server=cp.icr.io
        ```

## Kustomize

You can reference bases for the various tools here in your own kustomize overlay without 
explicitly cloning this repo, for example:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: product-catalog-cicd

resources:
- github.com/ibm-cloud-architecture/dba-gitops-catalog/ibm-automation/operator/base/?ref=main
```

This enables you to patch these resources for your specific environments. 
Note that none of these bases specify a namespace, in your kustomization overlay 
you can include the specific namespace you want to install the tool into.