set -o allexport
TF_VAR_folder_id=b1gsls3tk9b6uk0d01g9
YC_FOLDER_ID=b1gsls3tk9b6uk0d01g9
YC_CLOUD_ID=b1gij1dp8gfciqs3cuhk
YC_TOKEN=
source .source
tofu init 
tofu init -upgrade
tofu apply -input=false  -compact-warnings -auto-approve
yc k8s cluster get-credentials --id $(yc k8s cluster list  | grep 'RUNNING' | awk -F '|' '{print $2}')  --external --force
helm repo add yandex-s3 https://yandex-cloud.github.io/k8s-csi-s3/charts
helm install csi-s3 yandex-s3/csi-s3
kubectl apply -f ./manifest/storageClass.yaml
kubectl apply -f  manifest/pvc.yaml
kubectl apply -f  manifest/cm.yaml
kubectl apply -f  manifest/deployment.yaml