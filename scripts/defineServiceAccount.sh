#!/bin/bash


oc apply -f bootstrap/service-accounts.yaml -n ${CP4BA_AUTO_NAMESPACE}
oc adm policy add-scc-to-user privileged -z ibm-cp4ba-privileged -n ${CP4BA_AUTO_NAMESPACE}
oc adm policy add-scc-to-user anyuid -z ibm-cp4ba-anyuid -n ${CP4BA_AUTO_NAMESPACE}
