#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Running MCP Gateway Demo Client${NC}"

NAMESPACE="${NAMESPACE:-mcp-gateway}"

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python3 is required but not installed.${NC}" >&2
    exit 1
fi

# Install Python dependencies
echo -e "${YELLOW}Installing Python dependencies...${NC}"
pip3 install -r kind-deployment/sample-client/requirements.txt --quiet

# Check if gateway is accessible
echo -e "${YELLOW}Checking gateway accessibility...${NC}"
if ! curl -s -o /dev/null http://localhost:8000/health; then
    echo -e "${RED}MCP Gateway is not accessible at http://localhost:8000${NC}"
    echo -e "${YELLOW}Make sure you have run the previous deployment scripts and port forwarding is active.${NC}"
    echo -e "${YELLOW}You can start port forwarding with: kubectl port-forward -n ${NAMESPACE} svc/mcp-gateway 8000:8000${NC}"
    exit 1
fi

# Run the demo client
echo -e "${YELLOW}Running demo client...${NC}"
python3 kind-deployment/sample-client/demo_client.py

echo -e "${GREEN}Demo client completed!${NC}"