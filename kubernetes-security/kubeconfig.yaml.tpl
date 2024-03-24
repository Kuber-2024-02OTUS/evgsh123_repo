apiVersion: v1
kind: Config
clusters:
- name: minikube
  cluster:
    server: ${SERVER}
    certificate-authority: ca.crt
contexts:
- name: homework
  context:
    cluster: minikube
    namespace: homework
    user: cd
current-context: homework
users:
- name: cd
  user:
    tokenFile: token
