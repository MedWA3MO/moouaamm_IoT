#!/bin/bash
set -e

echo "[INFO] Updating system..."
apt-get update -y
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

# ============================
# Install Docker
# ============================
if ! command -v docker >/dev/null 2>&1; then
  echo "[INFO] Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  usermod -aG docker $USER
fi

# ============================
# Install kubectl
# ============================
if ! command -v kubectl >/dev/null 2>&1; then
  echo "[INFO] Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  install -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
fi

# ============================
# Install k3d
# ============================
if ! command -v k3d >/dev/null 2>&1; then
  echo "[INFO] Installing k3d..."
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# ============================
# Create K3d cluster
# ============================
if ! k3d cluster list | grep -q moouaamm-cluster; then
  echo "[INFO] Creating k3d cluster..."
  k3d cluster create moouaamm-cluster \
    --port "8888:80@loadbalancer"
fi

# ============================
# Kubernetes namespaces
# ============================
kubectl get ns argocd >/dev/null 2>&1 || kubectl create namespace argocd
kubectl get ns dev >/dev/null 2>&1 || kubectl create namespace dev

# ============================
# Install Argo CD
# ============================
if ! kubectl get deploy argocd-server -n argocd >/dev/null 2>&1; then
  echo "[INFO] Installing Argo CD..."
  kubectl apply -n argocd \
    -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
fi

echo "[INFO] Waiting for Argo CD to be ready..."
kubectl wait --for=condition=Available deploy/argocd-server \
  -n argocd --timeout=600s

# ============================
# Display Argo CD credentials
# ============================
ARGO_PWD=$(kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d)

echo "========================================"
echo " Argo CD is READY"
echo " Username : admin"
echo " Password : ${ARGO_PWD}"
echo "========================================"

echo "[INFO] Access Argo CD with:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"

kubectl apply -f p3/confs/config.yaml
