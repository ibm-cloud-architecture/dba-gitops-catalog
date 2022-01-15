
set -x
if [[ $# -ne 3 ]] 
then
	echo "parameters: secret_name source_namespace target_namespace"
else
    NSSRC=$2
	NSTGT=$3
	NAME=$1
	echo "create secret $NAME from $NSSRC to $NSTGT"
	oc get secret $1 --namespace=$NSSRC -o json \
	| jq  'del(.metadata.uid, .metadata.selfLink, .metadata.creationTimestamp, .metadata.ownerReferences)' \
	| jq -r '.metadata.namespace="'${NSTGT}'"' \
	| oc apply --namespace=$NSTGT -f -
fi
