#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building and loading Docker images${NC}"

CLUSTER_NAME="${CLUSTER_NAME:-mcp-gateway-demo}"
REGISTRY_PORT="5001"

# Build MCP Gateway image
echo -e "${YELLOW}Building MCP Gateway image...${NC}"
dotnet publish dotnet/Microsoft.McpGateway.Service/src/Microsoft.McpGateway.Service.csproj \
  --configuration Release \
  /p:ContainerRegistry=localhost:${REGISTRY_PORT} \
  /p:ContainerRepository=mcp-gateway \
  /p:ContainerImageTag=latest

# Build MCP Example Server image  
echo -e "${YELLOW}Building MCP Example Server image...${NC}"
docker build -f mcp-example-server/Dockerfile mcp-example-server -t localhost:${REGISTRY_PORT}/mcp-example:latest

# Push images to local registry
echo -e "${YELLOW}Pushing images to local registry...${NC}"
docker push localhost:${REGISTRY_PORT}/mcp-gateway:latest
docker push localhost:${REGISTRY_PORT}/mcp-example:latest

echo -e "${GREEN}Images built and pushed successfully!${NC}"
echo -e "${YELLOW}Available images:${NC}"
echo -e "  - localhost:${REGISTRY_PORT}/mcp-gateway:latest"
echo -e "  - localhost:${REGISTRY_PORT}/mcp-example:latest"