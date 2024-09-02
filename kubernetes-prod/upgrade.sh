echo "Start upgrade master"
MASTER_IP=$(tofu output -json | jq  '.master_ip_addr.value' | tr -d '"')
ssh-add ./out/ssh.key
cat <<  EOF  | ssh -o StrictHostKeyChecking=no -i out/ssh.key ubuntu@$MASTER_IP  'sudo bash'
        echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
        apt-get update
        apt-mark unhold kubeadm kubectl
        apt-get install -y kubeadm kubectl
        apt-mark hold kubeadm kubectl
        export KUBECONFIG=/etc/kubernetes/admin.conf
        kubeadm upgrade plan
        echo 'y' | kubeadm upgrade apply v1.31.0
        apt-mark unhold kubelet 
        apt-get install -y kubelet
        apt-mark hold kubelet 
        systemctl daemon-reload
        systemctl restart kubelet
        echo 'echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
        apt-get update
        apt-mark unhold kubeadm kubectl kubelet
        apt-get install -y kubeadm kubectl kubelet
        apt-mark hold kubeadm kubectl kubelet
        systemctl daemon-reload
        systemctl restart kubelet' >  upgrade-worker.sh
EOF
sleep 60
ssh   -o StrictHostKeyChecking=no -i out/ssh.key ubuntu@$MASTER_IP 'export KUBECONFIG=/etc/kubernetes/admin.conf ; sudo -E kubectl get nodes -o json' | python3 -c "
import json
import sys
data = json.load(sys.stdin)
for i in (data['items']):
   print(i['status']['addresses'][1]['address']+' '+i['status']['addresses'][0]['address'])"  | grep 'worker' | while read a b
 do
    echo "Upgrading on $a"
    cat  << EOF | ssh -A -o StrictHostKeyChecking=no -i out/ssh.key  ubuntu@$MASTER_IP  "bash" 
    export KUBECONFIG=/etc/kubernetes/admin.conf ; sudo -E kubectl  drain $a --ignore-daemonsets &&
    sleep 10 &&
    cat upgrade-worker.sh | ssh -o StrictHostKeyChecking=no  $b 'sudo bash' &&
    sleep 10 &&
    sudo -E kubectl uncordon $a &&
    sleep 10
EOF
    echo "Upgrade on $a done"
done   



