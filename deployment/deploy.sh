#!/bin/bash

red=$(tput setaf 1)

VERSION=1.0.0
APP_NAME=myapp
FLUX_DEPLOYMENT=false
OUTPUT_FILE=output.txt

echo "Starts new deployment..." > ${OUTPUT_FILE}

command -v kind >/dev/null 2>&1 || {
  echo >&2 "${red}I require kind but it's not installed.  Aborting." >> ${OUTPUT_FILE}
  exit 1
}

command -v helm >/dev/null 2>&1 || {
  echo >&2 "${red}I require helm but it's not installed.  Aborting." >> ${OUTPUT_FILE}
  exit 1
}

command -v kubectl >/dev/null 2>&1 || {
  echo >&2 "${red}I require kubectl but it's not installed.  Aborting." >> ${OUTPUT_FILE}
  exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                VERSION=$2
                shift
            else
                echo "Error: Argument for $1 is missing" >&2 >> ${OUTPUT_FILE}
                exit 1
            fi
            ;;
        -f|--flux)
            FLUX_DEPLOYMENT=true
            ;;
        *)    # Unknown option
            echo "Unknown option: $1" >&2 >> ${OUTPUT_FILE}
            exit 1
            ;;
    esac
    shift
done

checkGithubToken() {
    if [ -z "${GITHUB_TOKEN}" ]; then
        echo "Error: GITHUB_TOKEN is not set." >> ${OUTPUT_FILE}
        exit 1
    else
        echo "GITHUB_TOKEN is set."
    fi
}
checkGithubUser() {
    if [ -z "${GITHUB_USER}" ]; then
        echo "Error: GITHUB_USER is not set." >> ${OUTPUT_FILE}
        exit 1
    else
        echo "GITHUB_USER is set." >> ${OUTPUT_FILE}
    fi
}

helmDeployment() {
  echo 'Deploy using Kubectl and Helm CLIs' >> ${OUTPUT_FILE}
  NAMESPACE=$1
  kubectl create ns "${NAMESPACE}"
  OUTPUT=$(helm upgrade --install "myapp-release-${NAMESPACE}" myapp-chart --values myapp-chart/values.yaml -f "myapp-chart/values-${NAMESPACE}.yaml" --set image.tag="${VERSION}")
  echo "${OUTPUT}" >> ${OUTPUT_FILE}
}

fluxDeployment() {
  echo 'Deploy using FluxCD' >> ${OUTPUT_FILE}
  OUTPUT=$(flux bootstrap github \
  --owner="${GITHUB_USER}" \
  --repository=maven-hello-world \
  --branch=master \
  --path=./deployment/flux/infrastructure/dev \
  --personal)

  echo "${OUTPUT}" >> ${OUTPUT_FILE}
}

deploymentLogs(){
  kubectl wait -n "${NAMESPACE}" deployment/${APP_NAME} --for=condition=Available --timeout=30s

  NAMESPACE=$1
  OUTPUT=$(kubectl rollout status -n "${NAMESPACE}" deployment/${APP_NAME})
  echo "${OUTPUT}" >> ${OUTPUT_FILE}

  POD_NAME=$(kubectl get pods -n "${NAMESPACE}" --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep ${APP_NAME} | head -n 1)
  echo "POD Image Details:" >> ${OUTPUT_FILE}
  OUTPUT=$(kubectl describe pod -n "${NAMESPACE}" "${POD_NAME}" | grep Image)
  echo "${OUTPUT}" >> ${OUTPUT_FILE}

  echo "POD Logs:" >> ${OUTPUT_FILE}
  OUTPUT=$(kubectl logs -n "${NAMESPACE}" "${POD_NAME}")
  echo "${OUTPUT}" >> ${OUTPUT_FILE}
}

# FluxCD Installation checks
if [ ${FLUX_DEPLOYMENT} == true ]; then
  command -v flux >/dev/null 2>&1 || {
    echo >&2 "${red}I require flux but it's not installed.  Aborting." >> ${OUTPUT_FILE}
    exit 1
  }
  checkGithubToken
  checkGithubUser
  echo "Version: Managed By FluxCD" >> ${OUTPUT_FILE}
else
  echo "Version: ${VERSION}" >> ${OUTPUT_FILE}
fi



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
  fluxDeployment
else
  helmDeployment dev
fi

deploymentLogs dev

echo
echo "Deployment Done" >> ${OUTPUT_FILE}

cat ${OUTPUT_FILE}
