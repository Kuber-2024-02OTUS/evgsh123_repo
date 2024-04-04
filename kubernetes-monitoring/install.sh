#!/bin/bash
#build docker images
cd nginx-stub && \
   eval $(minikube -p minikube docker-env) && \
   docker build . -t nginx-stub && cd ..
#install kube-prometheos
helm install prom oci://registry-1.docker.io/bitnamicharts/kube-prometheus
#aplly 
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f serviceMonitor.yaml
#port forward
kubectl port-forward  svc/prometheus-operated 9090