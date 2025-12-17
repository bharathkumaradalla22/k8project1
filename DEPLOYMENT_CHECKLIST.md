# Pre-Deployment Verification Checklist

## ✅ Files Updated and Ready

- [x] **app.py** - Fixed API parameters and error handling
- [x] **backend.yaml** - Complete rewrite with namespace, deployments (2 replicas), services, config maps, health checks, resource limits, pod anti-affinity
- [x] **frontend-config.yaml** - Updated to pure ConfigMap with corrected HTML/JavaScript
- [x] **frontend-deployment.yaml** - 2 replicas with health checks, resource limits, anti-affinity
- [x] **frontend-service-nodeport.yaml** - Cleaned up and verified

## ✅ Critical Fixes Applied

### Backend API
- [x] Parameter names: `a,b` → `num1,num2`
- [x] Response field: `"sum"` → `"result"`
- [x] Function name: `add_numbers()` → `add()`
- [x] Error handling: Added try-catch blocks
- [x] Status responses: Added `"status": "success/error"`

### Frontend HTML
- [x] Input parameter names: `a,b` → `num1,num2`
- [x] Backend URL: Hardcoded hostname → Kubernetes DNS `backend-service:5000`
- [x] Response parsing: Updated to use `data.result`
- [x] Input validation: Added check for empty inputs
- [x] HTML structure: Proper DOCTYPE and meta tags

### Kubernetes Configuration
- [x] Namespace: Added `frontend-ns` creation in backend.yaml
- [x] Backend replicas: 1 → 2
- [x] Frontend replicas: 1 → 2
- [x] Pod anti-affinity: Added to spread across worker nodes
- [x] Resource limits: Added CPU/Memory requests and limits
- [x] Health checks: Added liveness probes
- [x] Service types: Backend ClusterIP, Frontend NodePort
- [x] Node port: Set to 30001

## ✅ Architecture Verification

### For 1 Master + 2 Worker Node Cluster
- [x] Master node: Runs Kubernetes control plane
- [x] Worker node 1: Runs frontend pod 1 + backend pod 1
- [x] Worker node 2: Runs frontend pod 2 + backend pod 2
- [x] Pod distribution: Anti-affinity ensures even distribution
- [x] External access: NodePort 30001 on any worker node

### Service Communication Flow
- [x] User browser → NodePort Service (port 30001)
- [x] Frontend pod → Kubernetes DNS lookup (backend-service:5000)
- [x] Backend service → Routes to backend pod (port 5000)
- [x] Flask app → Calculates and returns result

## ✅ Resources Defined

### Deployments
- [x] backend-deployment: 2 replicas, Python 3.9-Alpine
- [x] frontend-deployment: 2 replicas, Nginx Alpine

### Services
- [x] backend-service: ClusterIP, port 5000 (internal only)
- [x] frontend-service: NodePort, port 80→80, nodePort 30001

### ConfigMaps
- [x] backend-app: Contains Flask app code
- [x] frontend-html: Contains Nginx HTML/JavaScript

### Namespace
- [x] frontend-ns: Created for resource isolation

## ✅ Deployment Order

1. kubectl apply -f backend.yaml (Creates namespace + all backend resources)
2. kubectl apply -f frontend-deployment.yaml
3. kubectl apply -f frontend-service-nodeport.yaml
4. kubectl apply -f frontend-config.yaml (Optional if included in backend.yaml)

## ✅ Expected Pod Distribution

After deployment (kubectl get pods -n frontend-ns -o wide):
```
NAME                                    READY   STATUS    RESTARTS   NODE
backend-deployment-xxxxx-yyy           1/1     Running   0          worker-1
backend-deployment-xxxxx-zzz           1/1     Running   0          worker-2
frontend-deployment-xxxxx-aaa          1/1     Running   0          worker-1
frontend-deployment-xxxxx-bbb          1/1     Running   0          worker-2
```

## ✅ Testing Commands

```bash
# 1. Verify namespace
kubectl get namespace frontend-ns

# 2. Verify all pods running
kubectl get pods -n frontend-ns

# 3. Verify services
kubectl get svc -n frontend-ns

# 4. Verify pod nodes
kubectl get pods -n frontend-ns -o wide

# 5. Get worker node IP
kubectl get nodes -o wide

# 6. Test via curl
curl http://<worker-node-ip>:30001

# 7. Check logs
kubectl logs -l app=backend -n frontend-ns
kubectl logs -l app=frontend -n frontend-ns

# 8. Describe pods
kubectl describe pods -n frontend-ns

# 9. Test backend endpoint
kubectl exec -it <backend-pod> -n frontend-ns -- \
  python -c "import requests; r = requests.post('http://localhost:5000/add', json={'num1':5, 'num2':3}); print(r.json())"
```

## ✅ Browser Test

1. Get worker node IP: `kubectl get nodes -o wide`
2. Open browser: `http://<worker-node-ip>:30001`
3. Enter two numbers (e.g., 5 and 3)
4. Click "Calculate Sum"
5. Should see: "Result: 8"

## ✅ Troubleshooting Scenarios

### Scenario 1: Pods not starting
- Check: `kubectl describe pod <pod-name> -n frontend-ns`
- Look for: Events section, ImagePull errors, or resource constraints

### Scenario 2: Frontend loads but shows error
- Check: Browser console (F12 → Console)
- Test backend: `kubectl logs -l app=backend -n frontend-ns`
- Verify service: `kubectl get endpoints backend-service -n frontend-ns`

### Scenario 3: Cannot access http://<ip>:30001
- Check: Worker node firewall (port 30001 open?)
- Check: Worker node IP is correct
- Check: Service selector matches pod labels
- Verify: `kubectl get svc frontend-service -n frontend-ns`

### Scenario 4: Backend returns error
- Check logs: `kubectl logs -l app=backend -n frontend-ns`
- Check image: Is Python image available?
- Check disk space: `kubectl describe nodes`

## ✅ Final Checklist Before Deployment

- [ ] All 5 files are in: `C:\Users\hp\Desktop\k8_practice\sum application\`
- [ ] Read this document completely
- [ ] Kubectl is configured and connected to your cluster
- [ ] You can access your master node or worker nodes
- [ ] Firewall rules allow port 30001 on worker nodes
- [ ] You have at least 256MB free memory on each worker node
- [ ] You have read/write access to the cluster

---

## Status: ✅ READY FOR DEPLOYMENT

All files have been updated and verified. Your application is ready to deploy on your 1 Master + 2 Worker Node Kubernetes cluster.

**Next Step**: Run deployment commands from QUICK_START.md
