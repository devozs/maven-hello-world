#!/bin/bash

red=$(tput setaf 1)

VERSION=1.0.0
APP_NAME=myapp
FLUX_DEPLOYMENT=false

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
            if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                VERSION=$2
                shift
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        -f)
            FLUX_DEPLOYMENT=true
            ;;
        *)    # Unknown option
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
    shift
done

checkGithubToken() {
    if [ -z "${GITHUB_TOKEN}" ]; then
        echo "Error: GITHUB_TOKEN is not set."
        exit 1
    else
        echo "GITHUB_TOKEN is set."
    fi
}

# FluxCD Installation checks
if [ ${FLUX_DEPLOYMENT} == true ]; then
  command -v flux >/dev/null 2>&1 || {
    echo >&2 "${red}I require flux but it's not installed.  Aborting."
    exit 1
  }
  checkGithubToken
fi


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

kubectl cluster-info --context kind-${APP_NAME}

if [ ${FLUX_DEPLOYMENT} == true ]; then
  echo 'Deployment using FluxCD'

else
  helmDeployment dev
fi

helmDeployment() {
  NAMESPACE=$1
  kubectl create ns "${NAMESPACE}"
  helm upgrade --install "myapp-release-${NAMESPACE}" myapp-chart --values myapp-chart/values.yaml -f "myapp-chart/values-${NAMESPACE}.yaml" --set image.tag="${VERSION}"
  kubectl rollout status -n "${NAMESPACE} deployment/${APP_NAME}"
}

fluxDeployment(){
  echo 'Deploy using FluxCD'
}

verifyDeployment(){
  NAMESPACE=$1
  POD_NAME=$(kubectl get pods -n "${NAMESPACE}" --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep myapp | head -n 1)
  echo "POD Image Details:"
  kubectl describe pod -n" ${NAMESPACE}" "${POD_NAME}" | grep Image

  echo "POD Logs:"
  kubectl logs -n "${NAMESPACE}" "${POD_NAME}"
}

verifyDeployment dev

echo
echo "Deployment Done"
