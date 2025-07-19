# MCP Gateway Kind Deployment Guide

This guide demonstrates how to deploy the MCP Gateway in a local Kind (Kubernetes in Docker) cluster, complete with Helm chart deployment and a working example.

## Overview

This deployment includes:
- **MCP Gateway**: The main service deployed via Helm chart
- **MCP Example Server**: A sample MCP server to demonstrate functionality
- **Sample Client Application**: Python script showing how to interact with MCP servers through the gateway
- **Local Docker Registry**: For hosting images in the Kind cluster

## Prerequisites

Before starting, ensure you have the following tools installed:

- **Docker**: For container management
- **Kind**: Kubernetes in Docker for local clusters
- **kubectl**: Kubernetes CLI
- **Helm**: Kubernetes package manager
- **.NET 8 SDK**: For building the MCP Gateway
- **Python 3**: For running the demo client

### Installation Commands

```bash
# Install Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install Helm
curl https://get.helm.sh/helm-v3.14.0-linux-amd64.tar.gz | tar xz
sudo mv linux-amd64/helm /usr/local/bin/

# Install .NET 8 SDK (Ubuntu/Debian)
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y dotnet-sdk-8.0
```

## Quick Start

Run the complete deployment with a single command:

```bash
./kind-deployment/run-all.sh
```

Or follow the step-by-step process below.

## Step-by-Step Deployment

### 1. Create Kind Cluster

```bash
./kind-deployment/01-create-cluster.sh
```

This script:
- Creates a Kind cluster named `mcp-gateway-demo`
- Sets up a local Docker registry at `localhost:5001`
- Configures the cluster to use the local registry
- Exposes necessary ports for the application

### 2. Build and Push Images

```bash
./kind-deployment/02-build-images.sh
```

This script:
- Builds the MCP Gateway Docker image using .NET container publishing
- Builds the MCP Example Server Docker image
- Pushes both images to the local registry

### 3. Deploy MCP Gateway with Helm

```bash
./kind-deployment/03-deploy-gateway.sh
```

This script:
- Creates the `mcp-gateway` namespace
- Deploys MCP Gateway using the Helm chart
- Sets up port forwarding to access the gateway at `localhost:8000`
- Configures proper RBAC permissions for managing MCP servers

### 4. Deploy MCP Example Server

```bash
./kind-deployment/04-deploy-mcp-server.sh
```

This script:
- Deploys the MCP Example Server as a separate pod
- Creates a service to expose the MCP server internally
- Waits for the deployment to be ready

### 5. Run Demo Client

```bash
./kind-deployment/05-run-demo-client.sh
```

This script:
- Installs Python dependencies
- Runs a comprehensive demo client that:
  - Creates an MCP adapter through the gateway API
  - Tests connectivity to the MCP server
  - Demonstrates the complete workflow

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Demo Client   │    │   MCP Gateway   │    │  MCP Servers    │
│   (Python)      │───▶│   (Helm Chart)  │───▶│  (Kubernetes)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐              │
         └──────────────▶│ Kind Cluster    │◀─────────────┘
                        │ + Local Registry│
                        └─────────────────┘
```

## Helm Chart Details

The MCP Gateway Helm chart includes:

- **Deployment**: Main MCP Gateway application
- **Service**: ClusterIP service exposing the gateway
- **ServiceAccount**: With proper permissions for managing MCP servers
- **RBAC**: Role and RoleBinding for Kubernetes API access
- **ConfigMap**: Application configuration
- **Ingress**: Optional ingress configuration

### Key Helm Values

```yaml
image:
  repository: ghcr.io/nkbud/mcp-gateway
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8000

rbac:
  create: true
  rules:
    - apiGroups: ["apps"]
      resources: ["statefulsets"]
      verbs: ["get", "list", "create", "update", "delete", "patch", "watch"]
    - apiGroups: [""]
      resources: ["services", "pods", "endpoints"]
      verbs: ["get", "list", "create", "update", "delete", "patch", "watch"]
```

## Accessing the Services

Once deployed, you can access:

- **MCP Gateway API**: `http://localhost:8000`
- **Health Check**: `http://localhost:8000/health`
- **MCP Example Server** (via gateway): `http://localhost:8000/adapters/mcp-example/mcp`
- **OpenAPI Documentation**: Import `openapi/mcp-gateway.openapi.json` into tools like Postman

## Testing the Deployment

### Manual API Testing

1. **Create an adapter**:
   ```bash
   curl -X POST http://localhost:8000/adapters \
     -H "Content-Type: application/json" \
     -d '{
       "name": "test-adapter",
       "imageName": "mcp-example",
       "imageVersion": "latest",
       "description": "Test adapter"
     }'
   ```

2. **List adapters**:
   ```bash
   curl http://localhost:8000/adapters
   ```

3. **Check adapter status**:
   ```bash
   curl http://localhost:8000/adapters/test-adapter/status
   ```

### VS Code Integration

Create a `.vscode/mcp.json` file in your project:

```json
{
  "servers": {
    "mcp-example": {
      "url": "http://localhost:8000/adapters/mcp-example/mcp"
    }
  }
}
```

## Troubleshooting

### Common Issues

1. **Port 8000 already in use**:
   ```bash
   # Find the process using the port
   lsof -i :8000
   # Kill the port forwarding process if needed
   kill $(cat /tmp/mcp-gateway-port-forward.pid)
   ```

2. **Docker registry issues**:
   ```bash
   # Restart the registry
   docker restart kind-registry
   ```

3. **Images not found**:
   ```bash
   # Rebuild and push images
   ./kind-deployment/02-build-images.sh
   ```

4. **Pod not starting**:
   ```bash
   # Check pod logs
   kubectl logs -n mcp-gateway -l app.kubernetes.io/name=mcp-gateway
   
   # Check pod status
   kubectl describe pod -n mcp-gateway -l app.kubernetes.io/name=mcp-gateway
   ```

### Debugging Commands

```bash
# Check cluster status
kubectl cluster-info --context kind-mcp-gateway-demo

# List all resources in the namespace
kubectl get all -n mcp-gateway

# Check events
kubectl get events -n mcp-gateway --sort-by='.lastTimestamp'

# View service endpoints
kubectl get endpoints -n mcp-gateway

# Test internal connectivity
kubectl exec -n mcp-gateway deployment/mcp-gateway -- curl http://localhost:8000/health
```

## Cleanup

To remove all resources and clean up:

```bash
./kind-deployment/99-cleanup.sh
```

This will:
- Delete the Kind cluster
- Stop and remove the local registry
- Optionally clean up Docker images

## Customization

### Environment Variables

Customize the deployment by setting environment variables:

```bash
export CLUSTER_NAME="my-mcp-cluster"
export NAMESPACE="my-namespace" 
export REGISTRY_PORT="5002"
```

### Helm Values Override

Create a custom values file:

```yaml
# custom-values.yaml
replicaCount: 2

resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"  
    cpu: "500m"

ingress:
  enabled: true
  hosts:
    - host: mcp-gateway.local
      paths:
        - path: /
          pathType: Prefix
```

Deploy with custom values:

```bash
helm upgrade --install mcp-gateway ./helm/mcp-gateway \
  --namespace mcp-gateway \
  --values custom-values.yaml
```

## Production Considerations

When moving to production:

1. **Use external container registry** (GHCR, Docker Hub, etc.)
2. **Enable ingress** with proper TLS certificates
3. **Configure resource limits** and requests
4. **Enable autoscaling** based on load
5. **Set up monitoring** and logging
6. **Configure authentication** and authorization
7. **Use persistent storage** for stateful components
8. **Implement proper backup** and disaster recovery

## Support

For issues and questions:
- Check the [main repository](https://github.com/nkbud/mcp-gateway)
- Review existing issues and documentation
- Create a new issue if needed