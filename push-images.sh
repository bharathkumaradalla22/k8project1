#!/bin/bash

# Docker Registry Configuration
REGISTRY="YOUR_REGISTRY"  # e.g., docker.io/yourusername or localhost:5000
VERSION="latest"

# Image names
BACKEND_IMAGE="${REGISTRY}/k8s-calculator-backend:${VERSION}"
FRONTEND_IMAGE="${REGISTRY}/k8s-calculator-frontend:${VERSION}"

echo "Pushing Backend Docker Image..."
docker push ${BACKEND_IMAGE}
if [ $? -eq 0 ]; then
    echo "✓ Backend image pushed successfully"
else
    echo "✗ Backend image push failed"
    exit 1
fi

echo ""
echo "Pushing Frontend Docker Image..."
docker push ${FRONTEND_IMAGE}
if [ $? -eq 0 ]; then
    echo "✓ Frontend image pushed successfully"
else
    echo "✗ Frontend image push failed"
    exit 1
fi

echo ""
echo "==================================="
echo "All images pushed successfully!"
echo "==================================="
echo ""
echo "Update your Kubernetes YAML files with:"
echo "  Backend:  ${BACKEND_IMAGE}"
echo "  Frontend: ${FRONTEND_IMAGE}"
