#!/bin/bash
set -euo pipefail

# Script to deploy Jupyter to k3s

echo "Deploying Jupyter to k3s..."

# Apply all manifests in order
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/01-deployment.yaml
kubectl apply -f k8s/03-service.yaml
kubectl apply -f k8s/04-ingress.yaml

echo "Waiting for deployment to be ready..."
kubectl -n jupyter wait --for=condition=available --timeout=300s deployment/jupyter-notebook

echo "Deployment complete!"
echo ""
echo "Access Jupyter Notebook at:"
echo "  - NodePort: http://<your-node-ip>:30787"
echo "  - Ingress: http://jupyter.local (ensure DNS/hosts file is configured)"
echo ""
echo "Check status with: kubectl -n jupyter get all"
echo "View logs with: kubectl -n jupyter logs -l app=jupyter"