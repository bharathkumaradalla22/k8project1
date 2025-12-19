# Quick Deployment Checklist

## ✅ Pre-Deployment

- [ ] Ubuntu server is running
- [ ] SSH access available
- [ ] Kubernetes cluster is set up
- [ ] kubectl is working (`kubectl get nodes`)

## ✅ Deployment Steps

### 1. Transfer Files
```bash
git clone <your-repo>
cd k8project1
```

### 2. Setup Environment
```bash
chmod +x setup-ubuntu.sh
./setup-ubuntu.sh
newgrp docker
```

### 3. Deploy Application
```bash
chmod +x deploy-complete.sh
./deploy-complete.sh
```
Choose option 2 (Local Registry) when prompted

### 4. Configure AWS Security Group
- Open port 30001 (Frontend)
- Open port 30002 (Backend)

### 5. Verify
```bash
kubectl get pods -n namespace1
# Should see 4 pods running
```

### 6. Access
```
http://YOUR-MASTER-IP:30001
```

## ✅ Post-Deployment

- [ ] 4 pods running
- [ ] All pods status: Running
- [ ] Application accessible in browser
- [ ] Calculator works correctly

## 🔄 If Something Goes Wrong

```bash
# Check pods
kubectl get pods -n namespace1

# Check logs
kubectl logs <pod-name> -n namespace1

# Restart
kubectl rollout restart deployment backend-deployment -n namespace1
kubectl rollout restart deployment frontend-deployment -n namespace1

# Start over
kubectl delete namespace namespace1
./deploy-complete.sh
```

## 📞 Common Issues

| Issue | Fix |
|-------|-----|
| ImagePullBackOff | Use master IP instead of localhost:5000 |
| Can't access | Check AWS Security Group |
| Permission denied | Run `newgrp docker` |

---

**See [README.md](README.md) for complete documentation**
