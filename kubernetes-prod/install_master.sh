cloud-init status --wait
kubeadm init --upload-certs --pod-network-cidr=10.244.0.0/16
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
