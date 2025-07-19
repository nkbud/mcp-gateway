#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Deploying MCP Gateway using Helm${NC}"

CLUSTER_NAME="${CLUSTER_NAME:-mcp-gateway-demo}"
REGISTRY_PORT="5001"
NAMESPACE="${NAMESPACE:-mcp-gateway}"

# Create namespace if it doesn't exist
echo -e "${YELLOW}Creating namespace: ${NAMESPACE}${NC}"
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Deploy MCP Gateway using Helm
echo -e "${YELLOW}Installing MCP Gateway with Helm...${NC}"
helm upgrade --install mcp-gateway ./helm/mcp-gateway \
  --namespace ${NAMESPACE} \
  --set image.repository=localhost:${REGISTRY_PORT}/mcp-gateway \
  --set image.tag=latest \
  --set image.pullPolicy=IfNotPresent \
  --set env[0].name=ASPNETCORE_ENVIRONMENT \
  --set env[0].value=Development \
  --wait

# Wait for deployment to be ready
echo -e "${YELLOW}Waiting for deployment to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/mcp-gateway -n ${NAMESPACE}

# Show deployment status
echo -e "${GREEN}MCP Gateway deployed successfully!${NC}"
echo -e "${YELLOW}Deployment status:${NC}"
kubectl get pods -n ${NAMESPACE}
kubectl get svc -n ${NAMESPACE}

# Setup port forwarding (in background)
echo -e "${YELLOW}Setting up port forwarding...${NC}"
kubectl port-forward -n ${NAMESPACE} svc/mcp-gateway 8000:8000 &
PORT_FORWARD_PID=$!

echo -e "${GREEN}Setup complete!${NC}"
echo -e "${YELLOW}MCP Gateway is accessible at: http://localhost:8000${NC}"
echo -e "${YELLOW}To stop port forwarding, run: kill ${PORT_FORWARD_PID}${NC}"

# Save the PID for cleanup script
echo ${PORT_FORWARD_PID} > /tmp/mcp-gateway-port-forward.pid