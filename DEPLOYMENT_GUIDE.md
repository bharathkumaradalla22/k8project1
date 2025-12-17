# Kubernetes Calculator Application - Deployment Guide

## Overview
This is a distributed calculator application with:
- **Backend**: Flask API (2 replicas) for addition calculations
- **Frontend**: Nginx web server (2 replicas) with HTML interface
- **Configuration**: All services configured for a 1 master + 2 worker node cluster

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                       │
├─────────────────────────────────────────────────────────────┤
│ Master Node                                                 │
│ └─ API Server, Controller, Scheduler                        │
├─────────────────────────────────────────────────────────────┤
│ Worker Node 1              │ Worker Node 2                  │
│ ┌───────────────────────┐  │ ┌───────────────────────────┐  │
│ │ Frontend Pod 1        │  │ │ Frontend Pod 2            │  │
│ │ (Nginx on port 80)    │  │ │ (Nginx on port 80)        │  │
│ │ Service: port 80      │  │ │ Service: port 80          │  │
│ │ NodePort: 30001       │  │ │ NodePort: 30001           │  │
│ └───────────────────────┘  │ └───────────────────────────┘  │
│                             │                                │
│ ┌───────────────────────┐  │ ┌───────────────────────────┐  │
│ │ Backend Pod 1         │  │ │ Backend Pod 2             │  │
│ │ (Flask on port 5000)  │  │ │ (Flask on port 5000)      │  │
│ │ Service: ClusterIP    │  │ │ Service: ClusterIP        │  │
│ │          port 5000    │  │ │          port 5000        │  │
│ └───────────────────────┘  │ └───────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Fixed Issues

### 1. **API Endpoint Mismatch** ✓
   - **Problem**: Frontend called `/add` with `a` and `b` parameters, but backend expected `num1` and `num2`
   - **Solution**: Updated backend to accept `num1` and `num2` consistently across all files

### 2. **Function Name Inconsistency** ✓
   - **Problem**: Backend had `add_numbers()` function which wasn't matching the route `/add`
   - **Solution**: Changed to `add()` function for clarity

### 3. **Missing Namespace** ✓
   - **Problem**: Resources referenced `frontend-ns` namespace but it wasn't created
   - **Solution**: Added `Namespace` resource in backend.yaml

### 4. **Backend Accessibility** ✓
   - **Problem**: Frontend couldn't reach backend due to using window.location.hostname for backend URL
   - **Solution**: Updated to use Kubernetes service DNS: `http://backend-service:5000/add`

### 5. **Resource Distribution** ✓
   - **Problem**: Single replicas for both frontend and backend don't utilize 2 worker nodes
   - **Solution**: Set 2 replicas for each component with pod anti-affinity rules to distribute across nodes

### 6. **Missing Resource Limits** ✓
   - **Problem**: No resource requests/limits could cause scheduling issues
   - **Solution**: Added proper CPU and memory requests/limits

### 7. **Health Checks** ✓
   - **Problem**: No liveness probes to detect failed pods
   - **Solution**: Added HTTP liveness probes for both services

### 8. **Duplicate Definitions** ✓
   - **Problem**: Multiple deployment definitions across files creating conflicts
   - **Solution**: Consolidated all resources cleanly in backend.yaml with supporting files

## Deployment Steps

### 1. Create Namespace and Deploy All Resources
```bash
# Deploy from backend.yaml (contains namespace, configmaps, deployments, services)
kubectl apply -f backend.yaml

# Deploy frontend deployment configuration
kubectl apply -f frontend-deployment.yaml

# Deploy service configuration
kubectl apply -f frontend-service-nodeport.yaml

# Deploy config map (optional if using backend.yaml)
kubectl apply -f frontend-config.yaml
```

### 2. Verify Deployment
```bash
# Check namespace creation
kubectl get namespace frontend-ns

# Check deployments
kubectl get deployments -n frontend-ns

# Check pods (should have 2 frontend + 2 backend = 4 pods)
kubectl get pods -n frontend-ns

# Check services
kubectl get svc -n frontend-ns

# Check if pods are running
kubectl get pods -n frontend-ns -w  # Watch mode
```

### 3. Access the Application

Get any worker node IP (let's say your worker node IP is `192.168.1.100`):

```bash
# Access via NodePort 30001
http://192.168.1.100:30001
```

Or find the node IP:
```bash
kubectl get nodes -o wide
```

## Troubleshooting

### "Page Cannot Be Displayed"

1. **Check if pods are running**:
   ```bash
   kubectl get pods -n frontend-ns
   kubectl describe pod <pod-name> -n frontend-ns
   ```

2. **Check service endpoints**:
   ```bash
   kubectl get endpoints -n frontend-ns
   kubectl describe svc frontend-service -n frontend-ns
   ```

3. **Test backend connectivity from frontend pod**:
   ```bash
   kubectl exec -it <frontend-pod> -n frontend-ns -- /bin/sh
   # Inside pod:
   wget -O- http://backend-service:5000/add
   ```

4. **Check logs**:
   ```bash
   # Frontend logs
   kubectl logs <frontend-pod> -n frontend-ns
   
   # Backend logs
   kubectl logs <backend-pod> -n frontend-ns
   ```

5. **Check NetworkPolicy (if enabled)**:
   ```bash
   kubectl get networkpolicy -n frontend-ns
   ```

### Backend not responding

1. **Verify backend service is up**:
   ```bash
   kubectl get svc backend-service -n frontend-ns
   ```

2. **Check backend pod logs**:
   ```bash
   kubectl logs <backend-pod> -n frontend-ns
   ```

3. **Test backend directly from cluster**:
   ```bash
   kubectl run -it --rm debug --image=alpine --restart=Never -n frontend-ns -- \
     sh -c "wget -qO- http://backend-service:5000/add"
   ```

## File Descriptions

| File | Purpose |
|------|---------|
| `app.py` | Standalone Flask application (reference) |
| `backend.yaml` | Contains: Namespace, Backend ConfigMap, Backend Deployment (2 replicas), Backend Service (ClusterIP), Frontend ConfigMap, Frontend Deployment (2 replicas), Frontend Service (NodePort) |
| `frontend-config.yaml` | Frontend HTML ConfigMap (can be included in backend.yaml) |
| `frontend-deployment.yaml` | Frontend deployment specification with resource limits and health checks |
| `frontend-service-nodeport.yaml` | Frontend NodePort service for external access |

## Application Details

### Frontend
- **Port**: 80 (HTTP)
- **Replicas**: 2 (distributed across worker nodes)
- **Access**: http://<worker-node-ip>:30001
- **Features**: HTML5 UI with input fields and calculator button

### Backend
- **Port**: 5000 (Flask)
- **Replicas**: 2 (distributed across worker nodes)
- **Endpoint**: POST /add
- **Request Format**: `{"num1": <number>, "num2": <number>}`
- **Response Format**: `{"result": <sum>, "status": "success"}`

## Clean Up

```bash
# Delete all resources in namespace
kubectl delete namespace frontend-ns

# Or delete individually:
kubectl delete deployment -n frontend-ns --all
kubectl delete service -n frontend-ns --all
kubectl delete configmap -n frontend-ns --all
kubectl delete namespace frontend-ns
```

## Notes

- **Pod Anti-Affinity**: Configured to prefer spreading pods across different nodes
- **Health Checks**: Both services have liveness probes to auto-restart failed pods
- **Resource Limits**: Set to prevent resource starvation (can adjust based on node capacity)
- **Service Discovery**: Backend service is accessed via Kubernetes DNS: `backend-service:5000`
- **StatelessApplication**: All pods are stateless and can be created/destroyed freely
