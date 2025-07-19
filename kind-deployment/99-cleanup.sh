#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Cleaning up MCP Gateway Demo Environment${NC}"

CLUSTER_NAME="${CLUSTER_NAME:-mcp-gateway-demo}"
REGISTRY_NAME="kind-registry"

# Stop port forwarding if running
if [ -f /tmp/mcp-gateway-port-forward.pid ]; then
    PORT_FORWARD_PID=$(cat /tmp/mcp-gateway-port-forward.pid)
    if ps -p $PORT_FORWARD_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}Stopping port forwarding (PID: $PORT_FORWARD_PID)${NC}"
        kill $PORT_FORWARD_PID || true
    fi
    rm -f /tmp/mcp-gateway-port-forward.pid
fi

# Delete Kind cluster
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}Deleting Kind cluster: ${CLUSTER_NAME}${NC}"
    kind delete cluster --name="${CLUSTER_NAME}"
else
    echo -e "${YELLOW}Cluster ${CLUSTER_NAME} not found${NC}"
fi

# Stop and remove registry
if docker ps -a | grep -q "${REGISTRY_NAME}"; then
    echo -e "${YELLOW}Stopping and removing registry: ${REGISTRY_NAME}${NC}"
    docker stop "${REGISTRY_NAME}" || true
    docker rm "${REGISTRY_NAME}" || true
else
    echo -e "${YELLOW}Registry ${REGISTRY_NAME} not found${NC}"
fi

# Clean up Docker images (optional)
read -p "Do you want to remove local Docker images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cleaning up Docker images...${NC}"
    docker rmi localhost:5001/mcp-gateway:latest || true
    docker rmi localhost:5001/mcp-example:latest || true
fi

echo -e "${GREEN}Cleanup completed!${NC}"