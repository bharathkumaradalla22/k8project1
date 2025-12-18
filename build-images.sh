#!/bin/bash

# Docker Registry Configuration
# Replace these with your actual registry details
REGISTRY="YOUR_REGISTRY"  # e.g., docker.io/yourusername or localhost:5000
VERSION="latest"

# Image names
BACKEND_IMAGE="${REGISTRY}/k8s-calculator-backend:${VERSION}"
FRONTEND_IMAGE="${REGISTRY}/k8s-calculator-frontend:${VERSION}"

echo "Building Backend Docker Image..."
cd backend
docker build -t ${BACKEND_IMAGE} .
if [ $? -eq 0 ]; then
    echo "✓ Backend image built successfully: ${BACKEND_IMAGE}"
else
    echo "✗ Backend image build failed"
    exit 1
fi
cd ..

echo ""
echo "Building Frontend Docker Image..."
cd frontend
docker build -t ${FRONTEND_IMAGE} .
if [ $? -eq 0 ]; then
    echo "✓ Frontend image built successfully: ${FRONTEND_IMAGE}"
else
    echo "✗ Frontend image build failed"
    exit 1
fi
cd ..

echo ""
echo "==================================="
echo "Build Summary:"
echo "Backend:  ${BACKEND_IMAGE}"
echo "Frontend: ${FRONTEND_IMAGE}"
echo "==================================="
echo ""
echo "To push images to registry, run:"
echo "  docker push ${BACKEND_IMAGE}"
echo "  docker push ${FRONTEND_IMAGE}"
