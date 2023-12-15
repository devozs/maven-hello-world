#!/bin/bash

VERSION=1.0.0
APP_NAME=myapp

command -v kind >/dev/null 2>&1 || {
  echo >&2 "${red}I require kind but it's not installed.  Aborting."
  exit 1
}

command -v helm >/dev/null 2>&1 || {
  echo >&2 "${red}I require helm but it's not installed.  Aborting."
  exit 1
}

command -v kubectl >/dev/null 2>&1 || {
  echo >&2 "${red}I require kubectl but it's not installed.  Aborting."
  exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                VERSION=$2
                shift # Move past the value
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        *)    # Unknown option
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
    shift # Move to the next argument
done

echo "Version ${VERSION}"

kind delete cluster --name ${APP_NAME}

cat <<EOF | kind create cluster --name ${APP_NAME} --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: "0.0.0.0"
  apiServerPort: 6443
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

kubectl cluster-info --context ${APP_NAME}

NAMESPACE=dev
kubectl create ns ${NAMESPACE}
helm upgrade --install myapp-release-${NAMESPACE} myapp-chart --values myapp-chart/values.yaml -f myapp-chart/values-${NAMESPACE}.yaml --set image.tag="${VERSION}"

kubectl rollout status -n ${NAMESPACE} deployment/${APP_NAME}

POD_NAME=$(kubectl get pods -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep myapp | head -n 1)
echo "POD Image Details"
kubectl describe pod -n ${NAMESPACE} "${POD_NAME}" | grep Image

echo "POD Logs"
kubectl logs -n ${NAMESPACE} "${POD_NAME}"

echo "Deployment Done"
