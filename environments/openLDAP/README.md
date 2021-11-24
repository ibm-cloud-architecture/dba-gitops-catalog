# OpenLDAP

The product documentation is in [bitmani site](https://docs.bitnami.com/tutorials/create-openldap-server-kubernetes/).

To create a project to keep OpenLDAP with a secret do the following:

```sh
oc apply -k instances/openLDAP
```

which will create the name space, a secret, deploy a openLDAP pod and expose a service

adminpassword=adminpassword 
users=user01,user02,cpadmin 
passwords=password01,password02,password
  
```sh
echo "$(kubectl get secret openldap -n openldap -o json | jq -r .data.users | base64 --decode)"
echo "$(kubectl get secret openldap -n openldap -o json | jq -r .data.passwords | base64 --decode)"
```

Test it:

  ```sh
  oc rsh $(oc get po -o name -n openldap| grep ldap) -n openldap

  ldapsearch -x -H ldap://localhost:1389 dc=example,dc=org -D "cn=admin,dc=example,dc=org" -w adminpassword
  ```