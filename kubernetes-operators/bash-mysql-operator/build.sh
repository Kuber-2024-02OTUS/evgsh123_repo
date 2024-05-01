#!/bin/bash
#build docker images
eval $(minikube -p minikube docker-env) && \
docker build . -t  evgsh555/bash-mysql-operator