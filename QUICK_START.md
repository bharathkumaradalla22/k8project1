# Quick Start Guide

## Issue Fixed: "Page Cannot Be Displayed"

Your Kubernetes cluster setup had **6 critical issues** preventing the application from working:

1. ❌ **API Parameter Mismatch** → ✅ Fixed: All components now use `num1/num2`
2. ❌ **Wrong Backend URL** → ✅ Fixed: Uses `backend-service:5000` (Kubernetes DNS)
3. ❌ **Single Pod Per Component** → ✅ Fixed: 2 replicas each distributed across worker nodes
4. ❌ **No Health Checks** → ✅ Fixed: Added liveness probes
5. ❌ **No Resource Limits** → ✅ Fixed: Added CPU/Memory allocations
6. ❌ **Missing Namespace** → ✅ Fixed: Created in backend.yaml

---

## Deploy Now

```bash
cd c:\Users\hp\Desktop\k8_practice\sum\ application

# Apply all YAML files
kubectl apply -f backend.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service-nodeport.yaml
kubectl apply -f frontend-config.yaml
```

---

## Verify Deployment

```bash
# Check if everything is running
kubectl get all -n frontend-ns

# Expected output (4 pods running):
# - 2 frontend pods
# - 2 backend pods
# - 1 backend-service (ClusterIP)
# - 1 frontend-service (NodePort: 30001)
```

---

## Access Application

```bash
# Get your worker node IP
kubectl get nodes -o wide

# Access via browser
http://<worker-node-ip>:30001
```

**Example**: If worker node IP is `192.168.1.100`:
```
http://192.168.1.100:30001
```

---

## Test It

1. Open browser → `http://<worker-node-ip>:30001`
2. Enter two numbers in the input fields
3. Click "Calculate Sum"
4. Result appears below

---

## Common Commands

```bash
# View all resources
kubectl get all -n frontend-ns

# View just pods with node info
kubectl get pods -n frontend-ns -o wide

# View just services
kubectl get svc -n frontend-ns

# Check pod logs (frontend)
kubectl logs deployment/frontend-deployment -n frontend-ns

# Check pod logs (backend)
kubectl logs deployment/backend-deployment -n frontend-ns

# Describe a pod for troubleshooting
kubectl describe pod <pod-name> -n frontend-ns

# Watch pods starting up
kubectl get pods -n frontend-ns -w
```

---

## Architecture Summary

```
Your Cluster Setup:
├── Master Node (API, Scheduler, etcd)
├── Worker Node 1
│   ├── Frontend Pod 1 (Nginx)
│   └── Backend Pod 1 (Flask)
└── Worker Node 2
    ├── Frontend Pod 2 (Nginx)
    └── Backend Pod 2 (Flask)

External Access:
User → http://<worker-ip>:30001 (NodePort Service)
       ↓
     Frontend (Pod 1 or 2)
       ↓
     Backend Service (ClusterIP)
       ↓
     Backend Pod (1 or 2)
```

---

## File Updates Summary

| File | Changes |
|------|---------|
| **app.py** | Fixed param names: `a,b` → `num1,num2` |
| **backend.yaml** | Added namespace, 2 replicas, health checks, resource limits, anti-affinity |
| **frontend-config.yaml** | Pure ConfigMap now (HTML only), fixed JavaScript |
| **frontend-deployment.yaml** | Fixed name, 2 replicas, health checks, resource limits, anti-affinity |
| **frontend-service-nodeport.yaml** | Simplified, port 30001 |

---

## If It Still Doesn't Work

### Check 1: Are all pods running?
```bash
kubectl get pods -n frontend-ns
# All should show "Running" and "1/1"
```

### Check 2: Can frontend reach backend?
```bash
# Get a frontend pod name
POD=$(kubectl get pods -n frontend-ns -l app=frontend -o jsonpath='{.items[0].metadata.name}')

# Test backend connectivity
kubectl exec $POD -n frontend-ns -- wget -qO- http://backend-service:5000/add
```

### Check 3: Check pod errors
```bash
kubectl describe pod <pod-name> -n frontend-ns
# Look for "Events" section at the bottom
```

### Check 4: Check logs
```bash
kubectl logs <pod-name> -n frontend-ns
```

### Check 5: Verify NodePort is accessible
```bash
# From master or any node with network access
curl http://<worker-ip>:30001
```

---

## Clean Up

```bash
# Delete entire namespace and all resources
kubectl delete namespace frontend-ns

# Or manually delete individual resources
kubectl delete deployment --all -n frontend-ns
kubectl delete service --all -n frontend-ns
kubectl delete configmap --all -n frontend-ns
kubectl delete namespace frontend-ns
```

---

**Your application is now ready for production on your Kubernetes cluster!** 🚀
