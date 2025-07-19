#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up MCP Gateway on Kind cluster${NC}"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Docker is required but not installed.${NC}" >&2; exit 1; }
command -v kind >/dev/null 2>&1 || { echo -e "${RED}Kind is required but not installed.${NC}" >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}kubectl is required but not installed.${NC}" >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo -e "${RED}Helm is required but not installed.${NC}" >&2; exit 1; }

CLUSTER_NAME="${CLUSTER_NAME:-mcp-gateway-demo}"
REGISTRY_NAME="kind-registry"
REGISTRY_PORT="5001"

echo -e "${YELLOW}Creating Kind cluster: ${CLUSTER_NAME}${NC}"

# Create registry container unless it already exists
if [ "$(docker inspect -f '{{.State.Running}}' "${REGISTRY_NAME}" 2>/dev/null || true)" != 'true' ]; then
  echo -e "${YELLOW}Creating local registry...${NC}"
  docker run \
    -d --restart=always -p "127.0.0.1:${REGISTRY_PORT}:5000" --name "${REGISTRY_NAME}" \
    registry:2.7
fi

# Create kind cluster with registry config
cat <<EOF | kind create cluster --name="${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${REGISTRY_PORT}"]
    endpoint = ["http://${REGISTRY_NAME}:5000"]
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
  - containerPort: 8000
    hostPort: 8000
    protocol: TCP
EOF

# Connect the registry to the cluster network if not already connected
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${REGISTRY_NAME}")" = 'null' ]; then
  docker network connect "kind" "${REGISTRY_NAME}"
fi

# Document the local registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REGISTRY_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

echo -e "${GREEN}Kind cluster '${CLUSTER_NAME}' created successfully!${NC}"
echo -e "${YELLOW}Registry available at localhost:${REGISTRY_PORT}${NC}"
echo -e "${YELLOW}Cluster context: kind-${CLUSTER_NAME}${NC}"

# Set kubectl context
kubectl config use-context kind-${CLUSTER_NAME}

echo -e "${GREEN}Setup complete!${NC}"