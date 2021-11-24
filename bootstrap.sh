echo "Define IBM catalogs"
oc apply -f ibm-catalog/catalog_source.yaml
oc apply -k ibm-cp4a-catalog/overlays



echo "Define base operators"
oc apply -k operators/openshift-gitops/overlays/stable
oc apply -k operators/openshift-pipelines/overlays/stable
oc apply -k operators/sealed-secrets/overlays/default
oc apply -k operators/cn-postgresql/overlays

echo "Define Argocd projects"
oc apply -f bootstrap/argocd/cp4a-argo-project.yaml
oc apply -f bootstrap/argocd/odm-argo-project.yaml
oc apply -f bootstrap/argocd/ads-argo-project.yaml

echo "Start Main ArgonCD apps"
oc apply -k config/argocd/odm
oc apply -k config/argocd/ads