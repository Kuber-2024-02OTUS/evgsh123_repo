#Create sa
yc iam service-account create --name k8s-cluster-vault
FOLDER_ID=$(yc config get folder-id)
SA_ID=$(yc iam service-account get --name k8s-cluster-vault --format json | jq .id -r)
#Grant admin role
yc resource-manager folder add-access-binding --id $FOLDER_ID  --role admin --subject serviceAccount:$SA_ID

#Create cluster
yc managed-kubernetes cluster create \
 --name k8s-vault --network-name default \
 --zone ru-central1-a  --subnet-name default-ru-central1-a \
 --public-ip \
 --service-account-id ${SA_ID} --node-service-account-id ${SA_ID} 

#create worknode
 yc managed-kubernetes node-group create   \
 --name  k8s-gitops-workers \
 --cluster-name k8s-vault \
 --cores 2 \
 --memory 4 \
 --core-fraction 5 \
 --preemptible \
 --fixed-size 3 \
 --network-interface subnets=default-ru-central1-a,ipv4-address=nat

yc managed-kubernetes cluster get-credentials --external --name k8s-vault --force
cd consul && helmfile apply . && cd ..
cd vault && helmfile apply . && cd ..
while [[ "$(kubectl get pod -n vault  | grep -E 'vault-[0-9]' | grep  Running | wc -l)"  -lt "3" ]]; do echo 'waiting for all pod is running'; sleep 1 ;done

kubectl -n vault exec -it vault-0 -- vault operator init \
          -key-shares=3 \
          -key-threshold=3 

for i in 0 1 2; do
  for j in 1 2 3; do
    echo "Enter key number $j"
    kubectl -n vault exec -it  vault-$i -- vault operator unseal 
  done
done

kubectl -n vault  port-forward svc/vault 8200:8200 >/dev/null 2>&1 &

echo "Enter Token"
read token
export VAULT_TOKEN=$token
export VAULT_ADDR=http://127.0.0.1:8200

vault secrets enable -path otus/ kv-v2
vault kv put otus/cred 'username=otus'
vault kv patch otus/cred 'password=asajkjkahs'

kubectl apply -f sa.yaml

vault auth enable kubernetes
vault write auth/kubernetes/config \
    kubernetes_host=https://kubernetes.default.svc
vault policy write otus-policy otus-policy.hcl

vault write auth/kubernetes/role/otus \
      bound_service_account_names=vault-auth \
      bound_service_account_namespaces=vault \
      policies=default,otus-policy \
      ttl=24h

helmfile apply -f external-secrets-operator/
kubectl wait pod \
  --all \
  --for=condition=Ready \
  --namespace=vault
kubectl apply -f secretStore.yaml
kubectl apply -f externalSecret.yaml
