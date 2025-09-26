#!/bin/bash
set -euo pipefail

# Script to build Jupyter image and import it into k3s
# Must run from the repository root directory

# Change to the directory containing this script
cd "$(dirname "$0")"

echo "Building Jupyter Docker image from local Dockerfile..."
echo "Base image: jupyter/pyspark-notebook"
echo "Adding custom packages from requirements.txt..."

# Build using the same context and dockerfile path as docker-compose
docker build -t jupyter-docker-compose-with-nix:latest -f ./docker/jupyter/Dockerfile .

echo ""
echo "Exporting and importing image to k3s..."
docker save jupyter-docker-compose-with-nix:latest | sudo k3s ctr images import -

echo ""
echo "Verifying image was imported..."
sudo k3s ctr images list | grep jupyter

echo ""
echo "Image successfully imported to k3s!"
echo "You can now deploy with: ./deploy.sh"