#!/bin/bash

# ============================================================
# Ubuntu Prerequisites Installation Script
# For Kubernetes Calculator Application
# ============================================================

set -e  # Exit on any error

echo "============================================"
echo "Installing Prerequisites on Ubuntu"
echo "============================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script needs sudo privileges. It will prompt for your password."
    echo ""
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================
# 1. Update System
# ============================================
echo "📦 Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y
echo "✓ System updated"
echo ""

# ============================================
# 2. Install Docker
# ============================================
if command_exists docker; then
    echo "✓ Docker already installed"
    docker --version
else
    echo "🐳 Installing Docker..."
    
    # Install prerequisites
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Set up Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    
    echo "✓ Docker installed"
    docker --version
fi
echo ""

# ============================================
# 3. Configure Docker Permissions
# ============================================
echo "🔑 Configuring Docker permissions..."
sudo usermod -aG docker $USER
echo "✓ User $USER added to docker group"
echo "⚠️  You may need to logout/login or run: newgrp docker"
echo ""

# ============================================
# 4. Install Git (if not present)
# ============================================
if command_exists git; then
    echo "✓ Git already installed"
    git --version
else
    echo "📥 Installing Git..."
    sudo apt-get install -y git
    echo "✓ Git installed"
    git --version
fi
echo ""

# ============================================
# 5. Install useful tools
# ============================================
echo "🛠️  Installing useful tools..."
sudo apt-get install -y \
    curl \
    wget \
    vim \
    nano \
    net-tools \
    jq
echo "✓ Tools installed"
echo ""

# ============================================
# 6. Verify Kubernetes is installed
# ============================================
if command_exists kubectl; then
    echo "✓ kubectl found"
    kubectl version --client
else
    echo "⚠️  kubectl not found. Kubernetes should already be installed on your master node."
    echo "   If you need to install kubectl, run:"
    echo "   curl -LO https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    echo "   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"
fi
echo ""

# ============================================
# 7. Setup Docker Registry (Optional)
# ============================================
echo "Would you like to set up a local Docker registry? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "🗂️  Setting up local Docker registry..."
    
    # Run registry container
    docker run -d -p 5000:5000 --restart=always --name registry registry:2
    
    # Configure insecure registry
    sudo mkdir -p /etc/docker
    if [ -f /etc/docker/daemon.json ]; then
        echo "⚠️  /etc/docker/daemon.json exists. Backing up..."
        sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup
    fi
    
    echo '{
  "insecure-registries": ["localhost:5000"]
}' | sudo tee /etc/docker/daemon.json
    
    # Restart Docker
    sudo systemctl restart docker
    
    # Wait for registry to start
    sleep 5
    
    # Restart registry container
    docker start registry 2>/dev/null || true
    
    echo "✓ Local Docker registry running on localhost:5000"
    
    # Test registry
    if curl -s http://localhost:5000/v2/_catalog > /dev/null; then
        echo "✓ Registry is accessible"
    else
        echo "⚠️  Registry might not be fully ready yet. Wait a moment and test with:"
        echo "   curl http://localhost:5000/v2/_catalog"
    fi
else
    echo "⏭️  Skipping local registry setup"
    echo "   You can use Docker Hub or AWS ECR instead"
fi
echo ""

# ============================================
# Summary
# ============================================
echo "============================================"
echo "✅ Installation Complete!"
echo "============================================"
echo ""
echo "Installed components:"
echo "  ✓ Docker Engine"
echo "  ✓ Git"
echo "  ✓ Useful CLI tools"
if docker ps | grep -q registry; then
    echo "  ✓ Local Docker Registry (localhost:5000)"
fi
echo ""
echo "Next steps:"
echo "  1. Logout and login again (or run: newgrp docker)"
echo "  2. Test Docker: docker ps"
echo "  3. Clone your project: git clone <your-repo>"
echo "  4. Follow AWS_UBUNTU_DEPLOYMENT.md guide"
echo ""
echo "Registry options:"
echo "  - Local:     localhost:5000 (if installed)"
echo "  - Docker Hub: docker.io/yourusername"
echo "  - AWS ECR:   <account-id>.dkr.ecr.<region>.amazonaws.com"
echo ""
echo "============================================"
