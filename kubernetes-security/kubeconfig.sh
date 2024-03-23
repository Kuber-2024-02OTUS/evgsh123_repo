#!/bin/bash
kubectl get cm kube-root-ca.crt -o jsonpath="{['data']['ca\.crt']}" > ca.crt
kubectl create token cd -n homework --duration  24h > token
export SERVER=$(kubectl  cluster-info | grep  'Kubernetes control plane' | awk '{print $NF}' | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g')
cat kubeconfig.yaml.tpl | envsubst > kubeconfig.yaml
