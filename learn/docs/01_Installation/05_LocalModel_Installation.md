# LocalModel Installation

This guide covers installation of the LocalModel controller for efficient model caching.
本指南介绍了如何安装 LocalModel 控制器以实现高效的模型缓存.

## Prerequisites

**Required**: LocalModel MUST be installed after KServe controller is already installed.
必需: 必须在 KServe 控制器安装完成后再安装 LocalModel.

- **KServe Installation (Required)**: See [KServe Installation](https://kserve.github.io/website/docs/install/kserve-install)
- **Dependencies**: See [Standard Mode Dependencies](https://kserve.github.io/website/docs/install/dependencies#standard-mode-dependencies) or [Knative Mode Dependencies](https://kserve.github.io/website/docs/install/dependencies#knative-mode-dependencies)

> note
> LocalModel is an optional add-on component that requires **KServe controller** to be installed first. It currently only supports **InferenceService** workloads. Support for **LLMInferenceService** is planned for future releases.
> LocalModel 是一个可选的附加组件, 需要先安装 **KServe 控制器**. 目前它仅支持 **InferenceService** 工作负载. 对 **LLMInferenceService** 的支持计划在未来的版本中推出.
>

## Overview

LocalModel provides efficient model caching capabilities:
LocalModel 提供高效的模型缓存功能:

- **Controller**: Manages model cache lifecycle and policies
  **控制器**: 管理模型缓存生命周期和策略

- **Agent**: DaemonSet deployed on worker nodes for local caching
  **代理**: 部署在工作节点上的 DaemonSet, 用于本地缓存

- **Node Selection**: Target specific nodes for model caching
  **节点选择**: 针对特定节点进行模型缓存

- **Cache Policies**: Configurable cache size, eviction, and preloading
  **缓存策略**: 可配置的缓存大小、缓存清除和预加载

## Installation Methods

### Method 1: Kustomize

> Clone Repository First
> If you haven't cloned the KServe repository yet, see [Cloning the Repository](https://kserve.github.io/website/docs/install/dependencies#clone-repository).
>

```bash
# Install LocalModel (requires KServe to be already installed)
kubectl apply -k config/overlays/addons/localmodel
```

### Method 2: Helm

#### Install CRDs

```bash
# Using OCI registry (recommended)
helm install kserve-localmodel-crd oci://ghcr.io/kserve/charts/kserve-localmodel-crd \
  --version v0.17.0 \
  --namespace kserve \
  --create-namespace

# Or using local charts
helm install kserve-localmodel-crd ./charts/kserve-localmodel-crd \
  --namespace kserve \
  --create-namespace
```

#### Install LocalModel Resources

```bash
# Using OCI registry (recommended)
helm install kserve-localmodel-resources oci://ghcr.io/kserve/charts/kserve-localmodel-resources \
  --version v0.17.0 \
  --create-namespace \
  --namespace kserve \
  --wait

# Or using local charts
helm install kserve-localmodel-resources ./charts/kserve-localmodel-resources \
  --create-namespace \
  --namespace kserve \
  --wait
```

## Configuration Options

For detailed configuration options including node selector, resource limits, and storage configurations, see the [kserve-localmodel-resources Helm Chart README](https://github.com/kserve/kserve/blob/release-0.17/charts/kserve-localmodel-resources/README.md).
有关节点选择器、资源限制和存储配置等详细配置选项, 请参阅 [kserve-localmodel-resources Helm Chart README](https://github.com/kserve/kserve/blob/release-0.17/charts/kserve-localmodel-resources/README.md).

## Uninstallation

### Helm

```bash
# Remove resources
helm uninstall kserve-localmodel-resources -n kserve
helm uninstall kserve-localmodel-crd -n kserve
```

### Kustomize

```bash
# Remove LocalModel
kubectl delete -k config/overlays/addons/localmodel
```

### Cleanup

```bash
# Remove node labels
kubectl label nodes -l kserve/localmodel=worker kserve/localmodel-

# Clean up cached models (optional)
kubectl delete localmodelcache --all
kubectl delete localmodelnodegroup --all
```

## Next Steps

- [Getting Started Guide](https://kserve.github.io/website/docs/getting-started/quickstart-guide) - Deploy models with caching
- [LocalModel Configuration](https://kserve.github.io/website/docs/model-serving/generative-inference/modelcache/localmodel) - Advanced caching strategies
