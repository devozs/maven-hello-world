#!/bin/bash

echo "Installing Helm 3"
sudo curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

echo "Installing Kind"
sudo curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
sudo chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

echo "Installing kubectl"
sudo curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
sudo chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

