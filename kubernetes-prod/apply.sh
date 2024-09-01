set -o allexport
source .source
TF_VAR_folder_id=$YC_FOLDER_ID
tofu init 
tofu init -upgrade
tofu apply -input=false  -compact-warnings -auto-approve
chmod 600 out/ssh.key
sleep 60
cat install_master.sh | ssh  -o StrictHostKeyChecking=no -i out/ssh.key ubuntu@$(tofu output -json | jq  '.master_ip_addr.value' | tr -d '"')  'sudo bash' | tee out/master.log
sleep 5
echo 'cloud-init status --wait' > out/install_worker.sh 
cat out/master.log  | grep -A 1 'kubeadm join' >> out/install_worker.sh  
for i in $(tofu output -json | jq  '.worker_ip_addr.value.[]' | tr -d '"') ;do cat out/install_worker.sh | ssh  -o StrictHostKeyChecking=no -i out/ssh.key ubuntu@$i sudo bash ; done  
