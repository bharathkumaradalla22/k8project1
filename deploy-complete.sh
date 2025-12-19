#!/bin/bash

# ============================================================
# Complete Deployment Script for AWS Ubuntu
# Kubernetes Calculator Application
# ============================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================
# Configuration
# ============================================
echo -e "${CYAN}"
echo "============================================"
echo "  Kubernetes Calculator Deployment"
echo "============================================"
echo -e "${NC}"

# Check if we're in the right directory
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    echo -e "${RED}Error: backend/ or frontend/ directory not found!${NC}"
    echo "Please run this script from the k8project1 directory"
    exit 1
fi

# ============================================
# Step 1: Detect/Configure Registry
# ============================================
echo -e "${YELLOW}Step 1: Docker Registry Configuration${NC}"
echo ""

# Check if registry is already configured in build script
if grep -q "YOUR_REGISTRY" build-images.sh; then
    echo "Registry not yet configured. Please choose an option:"
    echo ""
    echo "1) Docker Hub (docker.io/username)"
    echo "2) Local Registry (localhost:5000)"
    echo "3) AWS ECR (account-id.dkr.ecr.region.amazonaws.com)"
    echo "4) Custom Registry"
    echo ""
    read -p "Enter choice [1-4]: " registry_choice
    
    case $registry_choice in
        1)
            read -p "Enter your Docker Hub username: " dockerhub_user
            REGISTRY="docker.io/$dockerhub_user"
            echo "Logging into Docker Hub..."
            docker login
            ;;
        2)
            REGISTRY="localhost:5000"
            # Check if registry is running
            if ! curl -s http://localhost:5000/v2/_catalog > /dev/null 2>&1; then
                echo "Starting local Docker registry..."
                docker run -d -p 5000:5000 --restart=always --name registry registry:2 || true
                sleep 3
            fi
            echo -e "${GREEN}✓ Using local registry${NC}"
            ;;
        3)
            read -p "Enter AWS Account ID: " aws_account
            read -p "Enter AWS Region (e.g., us-east-1): " aws_region
            REGISTRY="$aws_account.dkr.ecr.$aws_region.amazonaws.com"
            echo "Logging into AWS ECR..."
            aws ecr get-login-password --region $aws_region | docker login --username AWS --password-stdin $REGISTRY
            ;;
        4)
            read -p "Enter custom registry URL: " custom_registry
            REGISTRY="$custom_registry"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
    
    # Update build script
    echo "Updating build-images.sh with registry: $REGISTRY"
    sed -i "s|YOUR_REGISTRY|$REGISTRY|g" build-images.sh
    sed -i "s|YOUR_REGISTRY|$REGISTRY|g" push-images.sh
    
    # Update deployment files
    echo "Updating deployment YAML files..."
    sed -i "s|YOUR_REGISTRY|$REGISTRY|g" backend-deployment.yaml
    sed -i "s|YOUR_REGISTRY|$REGISTRY|g" frontend-deployment-updated.yaml
    
else
    # Registry already configured, extract it
    REGISTRY=$(grep "^REGISTRY=" build-images.sh | cut -d'"' -f2)
    echo -e "${GREEN}✓ Registry already configured: $REGISTRY${NC}"
fi

echo ""

# ============================================
# Step 2: Build Docker Images
# ============================================
echo -e "${YELLOW}Step 2: Building Docker Images${NC}"
echo ""

chmod +x build-images.sh
./build-images.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Images built successfully${NC}"
echo ""

# ============================================
# Step 3: Push Images to Registry
# ============================================
echo -e "${YELLOW}Step 3: Pushing Images to Registry${NC}"
echo ""

chmod +x push-images.sh
./push-images.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Push failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Images pushed successfully${NC}"
echo ""

# ============================================
# Step 4: Configure for Multi-Node (if needed)
# ============================================
if [ "$REGISTRY" == "localhost:5000" ]; then
    echo -e "${YELLOW}Step 4: Configuring for Local Registry${NC}"
    echo ""
    echo "⚠️  Important: You're using a local registry (localhost:5000)"
    echo ""
    
    # Get master node's IP
    MASTER_IP=$(hostname -I | awk '{print $1}')
    echo "Master node IP detected: $MASTER_IP"
    echo ""
    
    echo "For worker nodes to access images, you need to:"
    echo "1. Update deployment files to use $MASTER_IP:5000 instead of localhost:5000"
    echo "2. Configure each worker node to allow insecure registry"
    echo ""
    
    read -p "Update deployment files to use master IP? (y/n): " update_ip
    if [[ "$update_ip" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        sed -i "s|localhost:5000|$MASTER_IP:5000|g" backend-deployment.yaml
        sed -i "s|localhost:5000|$MASTER_IP:5000|g" frontend-deployment-updated.yaml
        echo -e "${GREEN}✓ Deployment files updated${NC}"
        
        echo ""
        echo "⚠️  Run this on EACH worker node:"
        echo ""
        echo -e "${CYAN}cat <<EOF | sudo tee /etc/docker/daemon.json"
        echo '{'
        echo "  \"insecure-registries\": [\"$MASTER_IP:5000\"]"
        echo '}'
        echo "EOF"
        echo ""
        echo "sudo systemctl restart docker"
        echo -e "${NC}"
        
        read -p "Press Enter when worker nodes are configured..."
    fi
else
    echo -e "${YELLOW}Step 4: Registry Configuration${NC}"
    echo -e "${GREEN}✓ Using external registry - no additional configuration needed${NC}"
fi

echo ""

# ============================================
# Step 5: Deploy to Kubernetes
# ============================================
echo -e "${YELLOW}Step 5: Deploying to Kubernetes${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl not found!${NC}"
    echo "Please install kubectl first"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}✗ Cannot connect to Kubernetes cluster!${NC}"
    echo "Please check your kubectl configuration"
    exit 1
fi

echo "Applying backend deployment..."
kubectl apply -f backend-deployment.yaml

echo ""
echo "Applying frontend deployment..."
kubectl apply -f frontend-deployment.yaml

echo ""
echo -e "${GREEN}✓ Deployments applied${NC}"
echo ""

# ============================================
# Step 6: Wait for Pods to be Ready
# ============================================
echo -e "${YELLOW}Step 6: Waiting for Pods to be Ready${NC}"
echo ""

echo "Waiting for backend pods..."
kubectl wait --for=condition=ready pod -l app=backend -n frontend-ns --timeout=180s || {
    echo -e "${RED}⚠️  Backend pods not ready within timeout${NC}"
    echo "Checking pod status..."
    kubectl get pods -n frontend-ns -l app=backend
}

echo ""
echo "Waiting for frontend pods..."
kubectl wait --for=condition=ready pod -l app=frontend -n frontend-ns --timeout=180s || {
    echo -e "${RED}⚠️  Frontend pods not ready within timeout${NC}"
    echo "Checking pod status..."
    kubectl get pods -n frontend-ns -l app=frontend
}

echo ""

# ============================================
# Step 7: Verify Deployment
# ============================================
echo -e "${YELLOW}Step 7: Deployment Status${NC}"
echo ""

echo "Pods:"
kubectl get pods -n frontend-ns
echo ""

echo "Services:"
kubectl get svc -n frontend-ns
echo ""

# ============================================
# Step 8: Get Access Information
# ============================================
echo -e "${YELLOW}Step 8: Access Information${NC}"
echo ""

# Try to get external IP
EXTERNAL_IP=$(curl -s http://checkip.amazonaws.com || hostname -I | awk '{print $1}')

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   Deployment Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Access your application:"
echo ""
echo -e "${CYAN}Frontend:${NC} http://$EXTERNAL_IP:30001"
echo -e "${CYAN}Backend:${NC}  http://$EXTERNAL_IP:30002/health"
echo ""

# Check if AWS security group message is needed
if [[ "$EXTERNAL_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${YELLOW}⚠️  AWS Security Group Check:${NC}"
    echo "Make sure these ports are open in your AWS Security Group:"
    echo "  - Port 30001 (Frontend)"
    echo "  - Port 30002 (Backend)"
    echo ""
fi

echo "Quick commands:"
echo "  Check pods:    kubectl get pods -n frontend-ns"
echo "  Check logs:    kubectl logs <pod-name> -n frontend-ns"
echo "  Restart:       kubectl rollout restart deployment <name> -n frontend-ns"
echo "  Delete all:    kubectl delete namespace frontend-ns"
echo ""

# ============================================
# Step 9: Test Application
# ============================================
echo -e "${YELLOW}Step 9: Testing Application${NC}"
echo ""

read -p "Would you like to test the backend health endpoint? (y/n): " test_backend
if [[ "$test_backend" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Testing backend health..."
    sleep 2
    
    # Test from within cluster
    BACKEND_POD=$(kubectl get pods -n frontend-ns -l app=backend -o jsonpath='{.items[0].metadata.name}')
    if [ ! -z "$BACKEND_POD" ]; then
        kubectl exec $BACKEND_POD -n frontend-ns -- curl -s http://localhost:5000/health
        echo ""
    fi
    
    # Test from external
    echo "Testing from external IP..."
    curl -s http://$EXTERNAL_IP:30002/health || echo "External access may need security group configuration"
fi

echo ""
echo -e "${GREEN}All done! 🚀${NC}"
echo ""
echo "If you encounter any issues:"
echo "  1. Check pod logs: kubectl logs <pod-name> -n frontend-ns"
echo "  2. Describe pod: kubectl describe pod <pod-name> -n frontend-ns"
echo "  3. Check events: kubectl get events -n frontend-ns --sort-by='.lastTimestamp'"
echo ""
