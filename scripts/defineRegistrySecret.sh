#!/bin/bash
key=$(getEntitlementKey)

if [[ $# -eq 0 ]]; then
   rname=ibm-entitlement-key
   nsname=openshift-operators
else
   if [[ $# -ne 2 ]]; then
      echo "Need secret name and namespace as arguments"
      exit 1
   fi
   rname=$1
   nsname=$2
fi

oc create secret docker-registry $rname \
    --docker-username=cp \
    --docker-password=$key \
    --docker-server=cp.icr.io \
    --namespace=$nsname
