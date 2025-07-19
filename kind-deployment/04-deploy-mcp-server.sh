#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Deploying MCP Example Server${NC}"

REGISTRY_PORT="5001"
NAMESPACE="${NAMESPACE:-mcp-gateway}"

# Deploy MCP Example Server using kubectl
echo -e "${YELLOW}Deploying MCP Example Server...${NC}"

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mcp-example-server
  namespace: ${NAMESPACE}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mcp-example-server
  template:
    metadata:
      labels:
        app: mcp-example-server
    spec:
      containers:
      - name: mcp-example-server
        image: localhost:${REGISTRY_PORT}/mcp-example:latest
        ports:
        - containerPort: 8000
        imagePullPolicy: IfNotPresent
---
apiVersion: v1
kind: Service
metadata:
  name: mcp-example-service
  namespace: ${NAMESPACE}
spec:
  selector:
    app: mcp-example-server
  ports:
  - protocol: TCP
    port: 8000
    targetPort: 8000
EOF

# Wait for deployment to be ready
echo -e "${YELLOW}Waiting for MCP Example Server to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/mcp-example-server -n ${NAMESPACE}

echo -e "${GREEN}MCP Example Server deployed successfully!${NC}"
kubectl get pods -n ${NAMESPACE} -l app=mcp-example-server