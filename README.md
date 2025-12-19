# Kubernetes Calculator Application - AWS Ubuntu Deployment

A simple calculator application demonstrating Kubernetes deployment with separate frontend (Nginx) and backend (Flask) services using Docker images.

---

## 📁 Project Structure

```
k8project1/
├── backend/
│   ├── app.py              # Flask API application
│   ├── requirements.txt    # Python dependencies
│   ├── Dockerfile          # Backend Docker image
│   └── .dockerignore       # Docker ignore file
│
├── frontend/
│   ├── index.html          # Web UI
│   ├── Dockerfile          # Frontend Docker image
│   └── .dockerignore       # Docker ignore file
│
├── backend-deployment.yaml # Backend Kubernetes deployment
├── frontend-deployment.yaml# Frontend Kubernetes deployment
│
├── setup-ubuntu.sh         # Install Docker and prerequisites
├── deploy-complete.sh      # Automated deployment script
├── build-images.sh         # Build Docker images
├── push-images.sh          # Push images to registry
│
├── README.md               # This file
└── ARCHITECTURE.md         # Architecture diagrams (optional reading)
```

---

## 🎯 What This Application Does

- **Frontend**: Web interface for calculator (runs on Nginx)
- **Backend**: REST API for calculations (runs on Flask)
- **Kubernetes**: Manages 2 replicas each (4 pods total)
- **High Availability**: Pods distributed across worker nodes

**Access Points:**
- Frontend UI: `http://<node-ip>:30001`
- Backend API: `http://<node-ip>:30002/health`

---

## 📋 Prerequisites

Before starting, ensure you have:

- ✅ AWS EC2 Ubuntu server (master node) running
- ✅ Kubernetes cluster set up (kubeadm with master + worker nodes)
- ✅ kubectl installed and configured
- ✅ SSH access to the server (.pem key file)
- ✅ Internet connection on the server

**Verify Kubernetes is working:**
```bash
kubectl get nodes
# Should show your master and worker nodes
```

---

## 🚀 Deployment Steps

### Step 1: Connect to Your Ubuntu Server

```bash
ssh -i your-key.pem ubuntu@your-master-ip
```

---

### Step 2: Transfer Project Files

**Option A: Using Git (Recommended)**
```bash
cd ~
git clone <your-repository-url>
cd k8project1
```

**Option B: Using SCP from your local machine**
```bash
# From your Windows machine:
cd D:\Dev\gitviews\k8project1
scp -i your-key.pem -r . ubuntu@your-master-ip:~/k8project1/

# Then on Ubuntu:
cd ~/k8project1
```

---

### Step 3: Run Setup Script (Install Docker)

```bash
# Make script executable
chmod +x setup-ubuntu.sh

# Run setup (installs Docker, Git, tools)
./setup-ubuntu.sh
```

**When prompted:**
- Choose `y` to install local Docker registry (easiest option)

**After installation completes:**
```bash
# Apply Docker group membership
newgrp docker

# Verify Docker works
docker ps
```

---

### Step 4: Run Automated Deployment

```bash
# Make deployment script executable
chmod +x deploy-complete.sh

# Run complete deployment
./deploy-complete.sh
```

**Follow the prompts:**
1. **Choose registry option:**
   - Option 2 (Local Registry - localhost:5000) - Recommended for testing
   - Option 1 (Docker Hub) - If you have Docker Hub account
   - Option 3 (AWS ECR) - If using AWS ECR

2. Script will automatically:
   - Build backend and frontend Docker images
   - Push images to registry
   - Deploy to Kubernetes
   - Wait for pods to be ready
   - Display access URLs

---

### Step 5: Configure AWS Security Group

**Important:** Open these ports in your AWS Security Group:

1. Go to **AWS Console** → **EC2** → **Security Groups**
2. Select your Kubernetes security group
3. Click **Edit Inbound Rules**
4. Add rules:

| Type | Port | Source | Description |
|------|------|--------|-------------|
| Custom TCP | 30001 | 0.0.0.0/0 | Frontend |
| Custom TCP | 30002 | 0.0.0.0/0 | Backend (optional) |

5. Click **Save Rules**

---

### Step 6: Verify Deployment

```bash
# Check all pods are running (should see 4 pods)
kubectl get pods -n frontend-ns

# Expected output:
# NAME                                   READY   STATUS    RESTARTS   AGE
# backend-deployment-xxxxx-yyyyy         1/1     Running   0          2m
# backend-deployment-xxxxx-zzzzz         1/1     Running   0          2m
# frontend-deployment-xxxxx-yyyyy        1/1     Running   0          2m
# frontend-deployment-xxxxx-zzzzz        1/1     Running   0          2m

# Check services
kubectl get svc -n frontend-ns

# Get your server's public IP
curl http://checkip.amazonaws.com
```

---

### Step 7: Access Application

Open your browser and navigate to:
```
http://YOUR-MASTER-IP:30001
```

**Test the calculator:**
1. Enter two numbers
2. Click "Calculate Sum"
3. Should see the result immediately

---

## 🔧 Manual Build Process (Alternative)

If you prefer to build manually instead of using `deploy-complete.sh`:

### Build Docker Images
```bash
chmod +x build-images.sh

# Edit registry in the script
nano build-images.sh
# Change: REGISTRY="YOUR_REGISTRY"
# To:     REGISTRY="localhost:5000"

# Build images
./build-images.sh
```

### Push Images
```bash
chmod +x push-images.sh
./push-images.sh
```

### Deploy to Kubernetes
```bash
# Deploy backend
kubectl apply -f backend-deployment.yaml

# Deploy frontend
kubectl apply -f frontend-deployment.yaml

# Check status
kubectl get pods -n frontend-ns
```

---

## 🐛 Troubleshooting

### Issue: Pods stuck in ImagePullBackOff

**Using Local Registry (localhost:5000):**

If worker nodes can't pull images:

```bash
# Get master node's private IP
hostname -I
# Example: 172.31.16.50

# Update deployment files
nano backend-deployment.yaml
# Change: localhost:5000
# To:     172.31.16.50:5000

nano frontend-deployment.yaml
# Same change

# On EACH worker node, run:
ssh worker-node
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "insecure-registries": ["172.31.16.50:5000"]
}
EOF
sudo systemctl restart docker
exit

# Redeploy
kubectl delete -f backend-deployment.yaml
kubectl delete -f frontend-deployment.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
```

---

### Issue: Can't access application in browser

1. **Check pods are running:**
   ```bash
   kubectl get pods -n frontend-ns
   # All should show "Running"
   ```

2. **Check AWS Security Group:**
   - Ensure ports 30001 and 30002 are open
   - Source should be 0.0.0.0/0

3. **Test from server:**
   ```bash
   curl http://localhost:30001
   # Should return HTML
   ```

---

### Issue: Permission denied when running docker

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply changes
newgrp docker

# Or logout and login again
```

---

### Issue: Pods CrashLoopBackOff

```bash
# Check pod logs
kubectl logs <pod-name> -n frontend-ns

# Check pod details
kubectl describe pod <pod-name> -n frontend-ns

# Common fixes:
# 1. Rebuild images
./build-images.sh
./push-images.sh

# 2. Restart deployments
kubectl rollout restart deployment backend-deployment -n frontend-ns
kubectl rollout restart deployment frontend-deployment -n frontend-ns
```

---

## 📊 Useful Commands

### Check Status
```bash
# All resources in namespace
kubectl get all -n frontend-ns

# Watch pods in real-time
kubectl get pods -n frontend-ns -w

# Check pod logs
kubectl logs <pod-name> -n frontend-ns

# Detailed pod information
kubectl describe pod <pod-name> -n frontend-ns

# Check recent events
kubectl get events -n frontend-ns --sort-by='.lastTimestamp'
```

### Update Application
```bash
# After making code changes:
cd ~/k8project1

# Rebuild images
./build-images.sh

# Push to registry
./push-images.sh

# Restart deployments (pulls new images)
kubectl rollout restart deployment backend-deployment -n frontend-ns
kubectl rollout restart deployment frontend-deployment -n frontend-ns
```

### Clean Up
```bash
# Delete everything
kubectl delete namespace frontend-ns

# Redeploy
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
```

### Check Resource Usage
```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods -n frontend-ns
```

---

## 🔄 Docker Registry Options

### Option 1: Local Registry (Recommended for Testing)
```bash
REGISTRY="localhost:5000"
```
- ✅ No external account needed
- ✅ Fast (local network)
- ✅ Free
- ⚠️ Need to configure worker nodes

### Option 2: Docker Hub
```bash
REGISTRY="docker.io/yourusername"
```
- ✅ Accessible anywhere
- ✅ Easy version control
- ⚠️ Requires Docker Hub account
- ⚠️ Need to run `docker login`

### Option 3: AWS ECR
```bash
REGISTRY="123456789012.dkr.ecr.us-east-1.amazonaws.com"
```
- ✅ AWS native integration
- ✅ High security
- ⚠️ Requires AWS credentials
- ⚠️ Need AWS CLI configured

---

## 📈 Architecture Overview

```
┌──────────────────────────────────────────────┐
│         AWS Ubuntu Master Node               │
│  - Docker & Local Registry (optional)        │
│  - kubectl                                   │
│  - Build & deployment scripts                │
└────────────────┬─────────────────────────────┘
                 │
                 │ Kubernetes API
                 │
┌────────────────┴─────────────────────────────┐
│         Kubernetes Cluster                   │
│                                              │
│  Namespace: frontend-ns                      │
│                                              │
│  ┌──────────────────┐  ┌──────────────────┐ │
│  │ Backend Pods (2) │  │Frontend Pods (2) │ │
│  │ Flask API        │  │ Nginx            │ │
│  │ Port: 5000       │  │ Port: 80         │ │
│  └──────────────────┘  └──────────────────┘ │
│                                              │
│  Services:                                   │
│  - backend-service (ClusterIP:5000)         │
│  - backend-service-nodeport (NodePort:30002)│
│  - frontend-service (NodePort:30001)        │
└──────────────────────────────────────────────┘
              │
              │ NodePort
              ▼
     ┌─────────────────┐
     │  User Browser   │
     │  :30001         │
     └─────────────────┘
```

For detailed architecture diagrams, see [ARCHITECTURE.md](ARCHITECTURE.md)

---

## ⏱️ Deployment Timeline

| Step | Duration |
|------|----------|
| Transfer files | 2-5 min |
| Run setup-ubuntu.sh | 5-10 min |
| Run deploy-complete.sh | 5-10 min |
| Configure security group | 2 min |
| **Total** | **15-27 min** |

---

## ✅ Success Checklist

After deployment, verify:

- [ ] 4 pods running in `frontend-ns` namespace
- [ ] All pods show "Running" status
- [ ] 3 services created (2 backend, 1 frontend)
- [ ] AWS Security Group ports 30001, 30002 open
- [ ] Application accessible at `http://master-ip:30001`
- [ ] Calculator performs addition correctly
- [ ] Backend health check works: `http://master-ip:30002/health`

---

## 🔐 Security Notes

- **NodePort Services**: Exposed for external access (ports 30001, 30002)
- **ClusterIP Service**: Internal backend communication only
- **Resource Limits**: Set to prevent pod resource exhaustion
- **Health Checks**: Liveness and readiness probes configured
- **Pod Anti-Affinity**: Ensures high availability across nodes

---

## 📚 Additional Resources

- **Architecture Details**: See [ARCHITECTURE.md](ARCHITECTURE.md)
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Docker Documentation**: https://docs.docker.com/

---

## 🆘 Getting Help

If you encounter issues:

1. Check pod status: `kubectl get pods -n frontend-ns`
2. Check pod logs: `kubectl logs <pod-name> -n frontend-ns`
3. Check pod details: `kubectl describe pod <pod-name> -n frontend-ns`
4. Check events: `kubectl get events -n frontend-ns --sort-by='.lastTimestamp'`

Common issues are covered in the **Troubleshooting** section above.

---

## 📝 Application Details

### Backend (Flask API)
- **Language**: Python 3.9
- **Framework**: Flask with CORS
- **Endpoints**:
  - `GET /health` - Health check
  - `POST /add` - Addition operation
- **Port**: 5000

### Frontend (Web UI)
- **Server**: Nginx Alpine
- **Files**: Static HTML/CSS/JavaScript
- **Port**: 80

### Kubernetes Configuration
- **Namespace**: frontend-ns
- **Replicas**: 2 for each service (4 pods total)
- **Pod Anti-Affinity**: Distributes pods across nodes
- **Resource Limits**: 
  - Backend: 128-256Mi RAM, 200-500m CPU
  - Frontend: 32-64Mi RAM, 50-100m CPU

---

**Repository**: https://github.com/yourusername/k8project1  
**Last Updated**: December 18, 2025

---

## 🎉 That's It!

Your Kubernetes calculator application should now be running. Open `http://your-master-ip:30001` and start calculating!
