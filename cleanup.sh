#!/bin/bash
set -euo pipefail

# Script to remove Jupyter deployment from k3s

echo "Removing Jupyter deployment from k3s..."

# Delete in reverse order
kubectl delete -f k8s/04-ingress.yaml --ignore-not-found
kubectl delete -f k8s/03-service.yaml --ignore-not-found
kubectl delete -f k8s/01-deployment.yaml --ignore-not-found

# Delete namespace last
kubectl delete -f k8s/00-namespace.yaml --ignore-not-found

echo ""
echo "Note: Your notebook data is preserved in the host directories:"
echo "  - /home/justin/2024/"
echo "  - /home/justin/2025/"
echo "  - $(pwd)/work/"
echo "  - $(pwd)/dot-jupyter/"

echo "Cleanup complete!"