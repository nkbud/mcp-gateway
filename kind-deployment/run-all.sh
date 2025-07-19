#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 MCP Gateway Complete Kind Deployment${NC}"
echo -e "${BLUE}=======================================${NC}"

# Change to the repo root
cd "$(dirname "$0")/.."

# Check if running in the correct directory
if [ ! -f "dotnet/Microsoft.McpGateway.Service/src/Microsoft.McpGateway.Service.csproj" ]; then
    echo -e "${RED}❌ Error: Please run this script from the repository root${NC}"
    exit 1
fi

echo -e "${YELLOW}This script will:${NC}"
echo -e "  1. Create a Kind cluster with local registry"
echo -e "  2. Build and push MCP Gateway and Example Server images"  
echo -e "  3. Deploy MCP Gateway using Helm chart"
echo -e "  4. Deploy MCP Example Server"
echo -e "  5. Run a demo client to test the complete workflow"
echo -e ""

read -p "Continue with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

echo -e "${GREEN}Starting deployment...${NC}"

# Step 1: Create cluster
echo -e "\n${BLUE}📦 Step 1: Creating Kind cluster${NC}"
./kind-deployment/01-create-cluster.sh

# Step 2: Build images  
echo -e "\n${BLUE}🔨 Step 2: Building and pushing images${NC}"
./kind-deployment/02-build-images.sh

# Step 3: Deploy gateway
echo -e "\n${BLUE}🚀 Step 3: Deploying MCP Gateway with Helm${NC}"
./kind-deployment/03-deploy-gateway.sh

# Step 4: Deploy MCP server
echo -e "\n${BLUE}🖥️  Step 4: Deploying MCP Example Server${NC}"
./kind-deployment/04-deploy-mcp-server.sh

# Wait a moment for everything to settle
echo -e "\n${YELLOW}⏳ Waiting for services to stabilize...${NC}"
sleep 15

# Step 5: Run demo client
echo -e "\n${BLUE}🎯 Step 5: Running demo client${NC}"
./kind-deployment/05-run-demo-client.sh

echo -e "\n${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${GREEN}=================================${NC}"
echo -e "\n${YELLOW}📋 What's running:${NC}"
echo -e "  • Kind cluster: ${BLUE}mcp-gateway-demo${NC}"
echo -e "  • Local registry: ${BLUE}localhost:5001${NC}"
echo -e "  • MCP Gateway: ${BLUE}http://localhost:8000${NC}"
echo -e "  • MCP Example Server: accessible via gateway"
echo -e ""
echo -e "${YELLOW}🔧 Useful commands:${NC}"
echo -e "  • View pods: ${BLUE}kubectl get pods -n mcp-gateway${NC}"
echo -e "  • View services: ${BLUE}kubectl get svc -n mcp-gateway${NC}"
echo -e "  • View logs: ${BLUE}kubectl logs -n mcp-gateway -l app.kubernetes.io/name=mcp-gateway${NC}"
echo -e "  • Test API: ${BLUE}curl http://localhost:8000/adapters${NC}"
echo -e ""
echo -e "${YELLOW}🧹 Cleanup:${NC}"
echo -e "  • Run: ${BLUE}./kind-deployment/99-cleanup.sh${NC}"
echo -e ""
echo -e "${GREEN}Happy MCP Gateway testing! 🎊${NC}"