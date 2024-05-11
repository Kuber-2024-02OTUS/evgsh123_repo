#Create sa
yc iam service-account create --name k8s-cluster-gitops
FOLDER_ID=$(yc config get folder-id)
SA_ID=$(yc iam service-account get --name k8s-cluster-gitops --format json | jq .id -r)
#Grant admin role
yc resource-manager folder add-access-binding --id $FOLDER_ID  --role admin --subject serviceAccount:$SA_ID

#Create cluster
yc managed-kubernetes cluster create \
 --name k8s-gitops --network-name default \
 --zone ru-central1-a  --subnet-name default-ru-central1-a \
 --public-ip \
 --service-account-id ${SA_ID} --node-service-account-id ${SA_ID} 

#create worknode
 yc managed-kubernetes node-group create   \
 --name  k8s-gitops-workers \
 --cluster-name k8s-gitops \
 --cores 2 \
 --memory 4 \
 --core-fraction 5 \
 --preemptible \
 --fixed-size 1 \
 --node-labels homework="true" \
 --network-interface subnets=default-ru-central1-a,ipv4-address=nat
 
 yc managed-kubernetes node-group create \
 --name  k8s-gitops-infra \
 --cluster-name k8s-gitops \
 --cores 2 \
 --memory 4 \
 --core-fraction 5 \
 --fixed-size 1 \
 --preemptible \
 --node-labels node-role=infra \
 --network-interface subnets=default-ru-central1-a,ipv4-address=nat

yc managed-kubernetes cluster get-credentials --external --name k8s-gitops --force
kubectl taint nodes -l node-role=infra node-role=infra:NoSchedule
#create standard storageclass for some old homework
kubectl get storageclass  yc-network-hdd -o yaml | sed 's/yc-network-hdd/standard/g' |kubectl apply -f -
kubectl patch storageclass standard --patch='{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class": "false"}}}'

#install argocd
cd argocd && helmfile apply && cd ..

#install all res for argocd
kubectl apply -f appproject.yaml
kubectl apply -f kubernetes-network.yaml
kubectl apply -f kubernetes-templating.yaml

