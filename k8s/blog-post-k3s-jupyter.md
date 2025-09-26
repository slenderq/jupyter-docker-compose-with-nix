# Deploying JupyterLab to k3s Without a Registry: A NixOS Journey

When you're running a local k3s cluster and want to deploy custom Docker images, the typical advice is "push to a registry." But what if you don't want the complexity of running a registry, or you're working in an air-gapped environment? Here's how I deployed my custom JupyterLab setup to k3s using direct image imports.

## The Challenge

I had a working Docker Compose setup for JupyterLab with custom packages (LangChain, xgboost, jupyterlab-vim) that I wanted to migrate to my k3s cluster. The requirements were:
- No external registry dependencies
- Preserve all my existing volume mounts
- Keep it simple for a single-node cluster
- Maintain compatibility with my NixOS configuration

## The Solution: Docker Save + k3s CTR Import

The key insight is that k3s uses containerd under the hood, and containerd can import images directly from tarballs. This gives us a registry-free workflow:

```bash
# Build locally with Docker
docker build -t jupyter-docker-compose-with-nix:latest -f ./docker/jupyter/Dockerfile .

# Export and import in one pipeline
docker save jupyter-docker-compose-with-nix:latest | sudo k3s ctr images import -
```

## The Implementation

### 1. Build Script (`build-and-import.sh`)
```bash
#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Building Jupyter Docker image from local Dockerfile..."
docker build -t jupyter-docker-compose-with-nix:latest -f ./docker/jupyter/Dockerfile .

echo "Exporting and importing image to k3s..."
docker save jupyter-docker-compose-with-nix:latest | sudo k3s ctr images import -

echo "Verifying image was imported..."
sudo k3s ctr images list | grep jupyter
```

### 2. Kubernetes Deployment

The deployment preserves all the volume mounts from Docker Compose:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jupyter-notebook
  namespace: jupyter
spec:
  template:
    spec:
      containers:
      - name: jupyter
        image: jupyter-docker-compose-with-nix:latest
        imagePullPolicy: Never  # Critical: tells k8s not to pull
        volumeMounts:
        - name: host-2024
          mountPath: /home/jovyan/work/2024
        - name: host-2025
          mountPath: /home/jovyan/work/2025
        - name: dot-jupyter
          mountPath: /home/jovyan/.juypter
        - name: work
          mountPath: /home/jovyan/work
      volumes:
      - name: host-2024
        hostPath:
          path: /home/justin/2024
      - name: host-2025
        hostPath:
          path: /home/justin/2025
      # ... more volumes
```

### 3. The Magic: `imagePullPolicy: Never`

This single line tells Kubernetes to never try pulling the image from a registry. Combined with our import process, k3s will use the locally imported image.

## NixOS Integration

To make the service easily accessible, I added a hostname entry to my NixOS configuration:

```nix
# In nixos-shared.nix
networking.extraHosts = ''
  192.168.0.185 jupyter.local
'';
```

After a `nixos-rebuild switch`, I can access JupyterLab at `http://jupyter.local:30787`.

## Lessons Learned

1. **k3s CTR is Your Friend**: The `k3s ctr` command gives direct access to containerd's image store
2. **hostPath Works Fine**: For single-node clusters, hostPath volumes are simpler than PVCs
3. **Skip the Registry**: For local development, this approach is faster and simpler
4. **Preserve Working Configs**: The deployment exactly mirrors the Docker Compose setup

## The Complete Workflow

```bash
# Build and import
./build-and-import.sh

# Deploy to k3s
./deploy.sh

# Access JupyterLab
open http://jupyter.local:30787
```

## Why This Matters

This approach is perfect for:
- Home labs running k3s
- Development environments
- Air-gapped deployments
- Quick prototyping without registry overhead
- NixOS users who want declarative configs without external dependencies

The key takeaway: you don't always need a registry. Sometimes, the simplest solution is the best one.

## Next Steps

While this works great for single-node clusters, multi-node deployments would need either:
- A shared registry (defeating our purpose)
- Running the import on each node
- Using an embedded registry mirror like Spegel

But for my home lab? This solution is exactly what I needed.

---

*Find the complete implementation at [github.com/slenderq/jupyter-docker-compose-with-nix](https://github.com/slenderq/jupyter-docker-compose-with-nix)*