#!/usr/bin/env python3
"""
Sample client application that demonstrates using MCP servers through the MCP Gateway.
This client will:
1. Create an MCP adapter through the gateway API
2. Test connecting to the MCP server via the gateway
3. Make sample API calls through the MCP server
"""

import requests
import json
import time
import sys
from typing import Dict, Any

class MCPGatewayClient:
    def __init__(self, gateway_url: str = "http://localhost:8000"):
        self.gateway_url = gateway_url
        self.session = requests.Session()

    def create_adapter(self, name: str, image_name: str, image_version: str, description: str = "") -> Dict[str, Any]:
        """Create a new MCP adapter."""
        url = f"{self.gateway_url}/adapters"
        payload = {
            "name": name,
            "imageName": image_name,
            "imageVersion": image_version,
            "description": description
        }
        
        print(f"Creating adapter '{name}'...")
        response = self.session.post(url, json=payload, headers={"Content-Type": "application/json"})
        
        if response.status_code in [200, 201]:
            print(f"✅ Adapter '{name}' created successfully")
            return response.json()
        else:
            print(f"❌ Failed to create adapter: {response.status_code} - {response.text}")
            return {}

    def get_adapter(self, name: str) -> Dict[str, Any]:
        """Get adapter information."""
        url = f"{self.gateway_url}/adapters/{name}"
        response = self.session.get(url)
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"❌ Failed to get adapter '{name}': {response.status_code} - {response.text}")
            return {}

    def get_adapter_status(self, name: str) -> Dict[str, Any]:
        """Get adapter deployment status."""
        url = f"{self.gateway_url}/adapters/{name}/status"
        response = self.session.get(url)
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"❌ Failed to get adapter status: {response.status_code} - {response.text}")
            return {}

    def wait_for_adapter_ready(self, name: str, timeout: int = 300) -> bool:
        """Wait for adapter to be ready."""
        print(f"Waiting for adapter '{name}' to be ready...")
        
        start_time = time.time()
        while time.time() - start_time < timeout:
            status = self.get_adapter_status(name)
            if status and status.get("ready", False):
                print(f"✅ Adapter '{name}' is ready!")
                return True
            
            print(f"⏳ Adapter status: {status.get('phase', 'Unknown')}")
            time.sleep(10)
        
        print(f"❌ Timeout waiting for adapter '{name}' to be ready")
        return False

    def test_mcp_connection(self, name: str) -> bool:
        """Test MCP server connection via gateway."""
        url = f"{self.gateway_url}/adapters/{name}/mcp"
        
        print(f"Testing MCP connection to '{name}'...")
        
        # Test basic connectivity
        try:
            response = self.session.get(url, timeout=10)
            if response.status_code == 200:
                print(f"✅ MCP server '{name}' is accessible")
                return True
            else:
                print(f"❌ MCP server connection failed: {response.status_code}")
                return False
        except requests.exceptions.RequestException as e:
            print(f"❌ Connection error: {e}")
            return False

    def list_adapters(self) -> list:
        """List all adapters."""
        url = f"{self.gateway_url}/adapters"
        response = self.session.get(url)
        
        if response.status_code == 200:
            adapters = response.json()
            print(f"📋 Found {len(adapters)} adapter(s)")
            for adapter in adapters:
                print(f"  - {adapter.get('name', 'unknown')}: {adapter.get('description', 'no description')}")
            return adapters
        else:
            print(f"❌ Failed to list adapters: {response.status_code} - {response.text}")
            return []

    def delete_adapter(self, name: str) -> bool:
        """Delete an adapter."""
        url = f"{self.gateway_url}/adapters/{name}"
        response = self.session.delete(url)
        
        if response.status_code in [200, 204]:
            print(f"✅ Adapter '{name}' deleted successfully")
            return True
        else:
            print(f"❌ Failed to delete adapter: {response.status_code} - {response.text}")
            return False

def main():
    print("🚀 MCP Gateway Demo Client")
    print("=" * 40)
    
    # Initialize client
    client = MCPGatewayClient()
    
    # Test connectivity to gateway
    try:
        response = requests.get(f"{client.gateway_url}/health", timeout=5)
        if response.status_code != 200:
            print("❌ Gateway health check failed")
            sys.exit(1)
    except:
        print("❌ Cannot connect to MCP Gateway. Make sure it's running at http://localhost:8000")
        sys.exit(1)
    
    print("✅ Connected to MCP Gateway")
    
    # List existing adapters
    print("\n📋 Listing existing adapters...")
    existing_adapters = client.list_adapters()
    
    # Create example adapter if it doesn't exist
    adapter_name = "mcp-example"
    adapter_exists = any(adapter.get('name') == adapter_name for adapter in existing_adapters)
    
    if not adapter_exists:
        print(f"\n🔧 Creating adapter '{adapter_name}'...")
        result = client.create_adapter(
            name=adapter_name,
            image_name="mcp-example",
            image_version="latest",
            description="Example MCP server for demonstration"
        )
        
        if result:
            # Wait for adapter to be ready
            if client.wait_for_adapter_ready(adapter_name):
                # Test MCP connection
                client.test_mcp_connection(adapter_name)
            else:
                print("❌ Adapter failed to become ready")
        else:
            print("❌ Failed to create adapter")
    else:
        print(f"✅ Adapter '{adapter_name}' already exists")
        # Test existing adapter
        client.test_mcp_connection(adapter_name)
    
    # Show final status
    print(f"\n📊 Final adapter list:")
    client.list_adapters()
    
    print("\n🎉 Demo completed!")
    print("\nYou can now:")
    print("  - Access the MCP server at: http://localhost:8000/adapters/mcp-example/mcp")
    print("  - View adapter logs with: kubectl logs -n mcp-gateway -l app.kubernetes.io/name=mcp-gateway")
    print("  - Connect VS Code MCP client to: http://localhost:8000/adapters/mcp-example/mcp")

if __name__ == "__main__":
    main()