# Jupyter-Docker-Compose with Nix and k3s Support

My personal JupyterLab environment with custom packages, Docker Compose, NixOS integration, and k3s deployment support.

## Overview

This repository provides a complete JupyterLab setup that can be deployed:
- Locally with Docker Compose
- On NixOS systems via auto-generated Nix configuration
- On k3s clusters without needing a container registry

## Features

- **Base Image**: `jupyter/pyspark-notebook` with PySpark support
- **Custom Packages**: 
  - JupyterLab Vim mode (v4.1.4)
  - Jupytext for notebook version control
  - XGBoost for machine learning
  - LangChain ecosystem (langgraph, langsmith, etc.)
  - Various data science tools
- **Persistent Storage**: 
  - Work directories mounted at `/home/justin/2024` and `/home/justin/2025`
  - Jupyter settings persistence
- **Multiple Deployment Options**: Docker Compose, NixOS service, or k3s

## Quick Start

### Docker Compose Deployment

```bash
docker-compose build
docker-compose up -d
```

Access JupyterLab at http://localhost:9998

### k3s Deployment (No Registry Required!)

```bash
# Build and import image directly to k3s
./build-and-import.sh

# Deploy to k3s
./deploy.sh
```

Access JupyterLab at http://<node-ip>:30787

### NixOS Integration

Generate NixOS configuration:
```bash
nix run github:aksiksi/compose2nix -- -project=jupyter
```

The generated `jupyterlab.nix` creates a systemd service that:
- Builds the Docker image locally
- Runs on port 7887
- Includes a desktop entry for easy access

## Directory Structure

```
├── docker/
│   └── jupyter/
│       └── Dockerfile          # Custom Jupyter image
├── k8s/                       # Kubernetes manifests
│   ├── 00-namespace.yaml
│   ├── 01-deployment.yaml
│   ├── 03-service.yaml
│   ├── 04-ingress.yaml
│   └── README.md              # Detailed k8s documentation
├── requirements.txt           # Python packages to install
├── work/                      # Persistent work directory
├── dot-jupyter/              # Jupyter configuration
├── build-and-import.sh       # k3s image import script
├── deploy.sh                 # k3s deployment script
└── cleanup.sh               # k3s cleanup script
```

## Customization

### Adding Python Packages

Edit `requirements.txt` and rebuild:
```bash
docker-compose build
# or for k3s:
./build-and-import.sh && kubectl -n jupyter rollout restart deployment/jupyter-notebook
```

### Modifying Volume Mounts

Update the relevant configuration:
- **Docker Compose**: Edit `docker-compose.yml`
- **k3s**: Edit `k8s/01-deployment.yaml`
- **NixOS**: Regenerate with compose2nix after updating docker-compose.yml

## k3s Deployment Details

The k3s deployment uses a unique approach that avoids the need for a container registry:

1. **Local Build**: Uses your existing Docker daemon to build the image
2. **Direct Import**: Pipes the image directly into k3s's containerd: `docker save | k3s ctr import`
3. **No Pull Policy**: Sets `imagePullPolicy: Never` to use the local image

This is perfect for:
- Home labs
- Air-gapped environments
- Development workflows
- Single-node clusters

For detailed k3s deployment information, see [k8s/README.md](k8s/README.md).

## Ports

- **Docker Compose**: Port 9998
- **NixOS Service**: Port 7887
- **k3s NodePort**: Port 30787

## Security Note

This setup runs JupyterLab without authentication (`--NotebookApp.token=`). Only use in trusted environments or add authentication for production use.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
