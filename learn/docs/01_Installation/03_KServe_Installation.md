# KServe Installation

This guide covers installation of the KServe controller for predictive AI model serving.
本指南涵盖了用于预测性人工智能模型服务的 KServe 控制器的安装.

## Prerequisites

Before installing KServe, ensure dependencies are installed based on your deployment mode:
安装 KServe 之前, 请确保已根据您的部署模式安装依赖项:

- **Knative Mode**: See [Knative Mode Dependencies](https://kserve.github.io/website/docs/install/dependencies#knative-mode-dependencies)
- **Standard Mode**: See [Standard Mode Dependencies](https://kserve.github.io/website/docs/install/dependencies#standard-mode-dependencies)

## Deployment Modes

KServe supports two deployment modes:
KServe 支持两种部署模式:

| Mode         | Description                                                                                                    |
| ------------ | -------------------------------------------------------------------------------------------------------------- |
| **Knative**  | Serverless deployment with Knative <br/> 使用 Knative 进行无服务器部署                                         |
| **Standard** | Raw Kubernetes deployments using base Kubernetes features <br/> 使用 Kubernetes 基本功能的原始 Kubernetes 部署 |

## Installation Methods

### Method 1: Kustomize

#### Knative Mode

> Clone Repository First
> If you haven't cloned the KServe repository yet, see [Cloning the Repository](https://kserve.github.io/website/docs/install/dependencies#clone-repository).
> 如果您还没有克隆 KServe 存储库, 请参阅 "克隆存储库"
>

```bash
# Install KServe with all components
kubectl apply -k config/overlays/standalone/kserve
```

For addon installation (when LLMIsvc is already installed):
对于插件安装(当 LLMIsvc 已安装时):

```bash
# Install only KServe component (no base resources, reuses existing namespace)
kubectl apply -k config/overlays/addons/kserve
```

#### Standard Mode

```bash
# Set deployment mode to Standard
# Edit the inferenceservice ConfigMap
vi config/configmap/inferenceservice.yaml

# Change the deploy section to:
# deploy: |
#   {
#     "defaultDeploymentMode": "Standard"
#   }

# Apply
kubectl apply -k config/overlays/standalone/kserve
```

#### Install ClusterServingRuntimes

```bash
# Install all runtimes
kubectl apply -k config/runtimes
```

### Method 2: Helm

#### Install CRDs

First, install the KServe CRDs:

```bash
# Using OCI registry (recommended)
helm install kserve-crd oci://ghcr.io/kserve/charts/kserve-crd \
  --version v0.17.0 \
  --namespace kserve \
  --create-namespace

# Or using local charts
helm install kserve-crd ./charts/kserve-crd \
  --namespace kserve \
  --create-namespace
```

#### Install KServe Resources

**Knative Mode**:

```bash
helm install kserve-resources oci://ghcr.io/kserve/charts/kserve-resources \
  --version v0.17.0 \
  --namespace kserve \
  --set kserve.controller.deploymentMode=Knative \
  --wait
```

**Standard Mode**:

```bash
helm install kserve-resources oci://ghcr.io/kserve/charts/kserve-resources \
  --version v0.17.0 \
  --namespace kserve \
  --set kserve.controller.deploymentMode=Standard \
  --wait
```

**Addon Installation (when LLMIsvc is already installed)**:
插件安装(当 LLMIsvc 已安装时):

```bash
helm install kserve-resources oci://ghcr.io/kserve/charts/kserve-resources \
  --version v0.17.0 \
  --namespace kserve \
  --set kserve.createSharedResources=false \
  --wait
```

### Method 3: Installation Scripts

#### Quick Install (All-in-One)

**Knative Mode**:

```bash
cd kserve

# Install dependencies + KServe
./hack/setup/quick-install/kserve-knative-mode-full-install-helm.sh

# Or use with-manifest version (no clone needed, includes embedded manifests)
curl -fsSL https://github.com/kserve/kserve/releases/download/v0.17.0/kserve-knative-mode-full-install-with-manifests.sh
| bash
```

**Standard Mode**:

```bash
cd kserve

# Install dependencies + KServe
./hack/setup/quick-install/kserve-standard-mode-full-install-helm.sh

# Or use with-manifest version (no clone needed, includes embedded manifests)
curl -fsSL https://github.com/kserve/kserve/releases/download/v0.17.0/kserve-standard-mode-full-install-with-manifests.sh
| bash
```

## Configuration Helm Options

For detailed configuration options including deployment mode, gateway settings, resource limits, and runtime configurations, see the [kserve-resources Helm Chart README](https://github.com/kserve/kserve/blob/release-0.17/charts/kserve-resources/README.md).
有关部署模式、网关设置、资源限制和运行时配置等详细配置选项, 请参阅 [kserve-resources Helm Chart README](https://github.com/kserve/kserve/blob/release-0.17/charts/kserve-resources/README.md).

## Uninstallation

### Helm

```bash
# Remove resources
helm uninstall kserve-runtime-configs -n kserve
helm uninstall kserve-resources -n kserve
helm uninstall kserve-crd -n kserve

# Remove namespace
kubectl delete namespace kserve
```

### Kustomize

```bash
# Remove KServe
kubectl delete -k config/overlays/standalone/kserve
```

### Scripts

```bash
# Uninstall everything(dependencies + KServe) using helm quick install script from repo
./hack/setup/quick-install/kserve-knative-mode-full-install-helm.sh --uninstall

# Uninstall everything(dependencies + KServe) using kustomize quick install script
curl -fsSL https://github.com/kserve/kserve/releases/download/v0.17.0/kserve-knative-mode-full-install-with-manifests.sh
| bash -s -- --uninstall

# Uninstall KServe by individual script
UNINSTALL=true ./hack/setup/infra/manage.kserve-helm.sh
```

## Next Steps

- [Install LLMIsvc Controller](https://kserve.github.io/website/docs/install/llmisvc-install) - For generative AI workloads
- [Install LocalModel Controller](https://kserve.github.io/website/docs/install/localmodel-install) - For model caching
- [Getting Started Guide](https://kserve.github.io/website/docs/getting-started/quickstart-guide) - Deploy your first model
