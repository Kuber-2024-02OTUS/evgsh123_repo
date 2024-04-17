
#Create sa
yc iam service-account create --name k8s-cluster-logging
FOLDER_ID=$(yc config get folder-id)
SA_ID=$(yc iam service-account get --name k8s-cluster-logging --format json | jq .id -r)
#Grant admin role
yc resource-manager folder add-access-binding --id $FOLDER_ID  --role admin --subject serviceAccount:$SA_ID
#Generate s3 secret
if [ ! -f .sa.secret ]; then
  yc iam access-key create  --service-account-id $SA_ID >  .sa.secret
fi 

export accessKeyId=$(cat .sa.secret | grep 'key_id' | awk -F ':' '{print $2}')
export secretAccessKey=$(cat .sa.secret | grep 'secret' | awk -F ':' '{print $2}')

#Templating values for loki
cat loki/values.yaml.tpl | envsubst > loki/values.yaml

#Create cluster
yc managed-kubernetes cluster create \
 --name k8s-logging --network-name default \
 --zone ru-central1-a  --subnet-name default-ru-central1-a \
 --public-ip \
 --service-account-id ${SA_ID} --node-service-account-id ${SA_ID} 

#create worknode
 yc managed-kubernetes node-group create   \
 --name  k8s-logging-workers \
 --cluster-name k8s-logging \
 --cores 2 \
 --memory 4 \
 --core-fraction 5 \
 --preemptible \
 --fixed-size 1 \
 --network-interface subnets=default-ru-central1-a,ipv4-address=nat
 
 yc managed-kubernetes node-group create \
 --name  k8s-logging-infra \
 --cluster-name k8s-logging \
 --cores 2 \
 --memory 4 \
 --core-fraction 5 \
 --fixed-size 1 \
 --preemptible \
 --node-labels node-role=infra \
 --network-interface subnets=default-ru-central1-a,ipv4-address=nat

yc managed-kubernetes cluster get-credentials --external --name k8s-logging --force
kubectl taint nodes -l node-role=infra node-role=infra:NoSchedule
kubectl create ns monitoring

#Create bucket
yc storage bucket create  monitoring-loki-chunks
yc storage bucket create  monitoring-loki-ruler
yc storage bucket create  monitoring-loki-admin

yc storage bucket update --name monitoring-loki-chunks  \
    --grants grant-type=grant-type-account,grantee-id=${SA_ID},permission=permission-full-control

yc storage bucket update --name monitoring-loki-ruler   \
    --grants grant-type=grant-type-account,grantee-id=${SA_ID},permission=permission-full-control

yc storage bucket update --name monitoring-loki-admin  \
    --grants grant-type=grant-type-account,grantee-id=${SA_ID},permission=permission-full-control

# Start apps
cd loki && helmfile apply; cd ..
cd promtail && helmfile apply; cd ..
cd grafana && helmfile apply; cd ..

