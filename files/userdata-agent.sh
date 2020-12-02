#!/bin/bash -xe

/etc/eks/bootstrap.sh ${CLUSTER_NAME}

curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
export PATH=/usr/local/bin:$PATH
aws eks --region eu-west-1 update-kubeconfig --name rancher-cluster
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
kubectl create namespace cattle-system || echo "Namespace already exists"
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.0.4/cert-manager.crds.yaml
kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager  --version v1.0.4
helm install rancher rancher-stable/rancher  --namespace cattle-system --set hostname=container-management.connectholland.nl --set ingress.tls.source=letsEncrypt --set letsEncrypt.email=hosting+rancher-le@connectholland.nl --version 2.5.3