# LLMInferenceService Installation
LLM 推理服务安装

This guide covers installation of the LLMInferenceService controller for generative AI model serving.
本指南涵盖了生成式 AI 模型服务的 LLMInferenceService 控制器的安装.

## Prerequisites

Before installing LLMInferenceService, ensure dependencies are installed:
安装 LLMInferenceService 之前, 请确保已安装所有依赖项:

- **LLMIsvc Dependencies**: See [LLMIsvc Mode Dependencies](https://kserve.github.io/website/docs/install/dependencies#llmisvc-dependencies)

Required infrastructure:
所需基础设施:

- cert-manager
- Gateway API CRDs and Extension CRDs
- Envoy Gateway
- Envoy AI Gateway
- Gateway API resources (GatewayClass, Gateway)
- LWS Operator (LeaderWorkerSet)
- External Load Balancer (for local clusters)

## Overview

LLMInferenceService provides optimized serving for generative AI models with features
LLMInferenceService 为具有特征的生成式 AI 模型提供优化的服务

## Installation Methods

### Method 1: Kustomize

> Clone Repository First
> If you haven't cloned the KServe repository yet, see [Cloning the Repository](https://kserve.github.io/website/docs/install/dependencies#clone-repository).
>

```bash
# Install LLMInferenceService standalone
kubectl apply -k config/overlays/standalone/llmisvc
```

For addon installation (when KServe is already installed):
对于插件安装(当 KServe 已安装时):

```bash
# Install only LLMInferenceService component (no base resources, reuses existing namespace)
kubectl apply -k config/overlays/addons/llmisvc
```

For LLMInferenceServiceConfigs installation
用于 LLMInferenceServiceConfigs 安装

```bash
kubectl apply -k config/llmisvcconfig
```

### Method 2: Helm

#### Install CRDs

```bash
# Using OCI registry (recommended)
helm install kserve-llmisvc-crd oci://ghcr.io/kserve/charts/kserve-llmisvc-crd \
  --version v0.17.0 \
  --namespace kserve \
  --create-namespace

# Or using local charts
helm install kserve-llmisvc-crd ./charts/kserve-llmisvc-crd \
  --namespace kserve \
  --create-namespace
```

#### Install LLMInferenceService Resources
安装 LLMInferenceService 资源

```bash
# Using OCI registry (recommended)
helm install kserve-llmisvc-resources oci://ghcr.io/kserve/charts/kserve-llmisvc-resources \
  --version v0.17.0 \
  --create-namespace \
  --namespace kserve \
  --wait

# Or using local charts
helm install kserve-llmisvc-resources ./charts/kserve-llmisvc-resources \
  --create-namespace \
  --namespace kserve \
  --wait
```

**Addon Installation (when KServe is already installed)**:
插件安装(当 KServe 已安装时):

```bash
helm install kserve-llmisvc-resources oci://ghcr.io/kserve/charts/kserve-llmisvc-resources \
  --version v0.17.0 \
  --create-namespace \
  --namespace kserve \
  --set kserve.createSharedResources=false
```

#### Install LLMInferenceServiceConfigs
安装 LLMInferenceServiceConfigs

Install pre-configured templates for common LLM frameworks:
安装常用 LLM 框架的预配置模板:

```bash
helm install kserve-runtime-configs oci://ghcr.io/kserve/charts/kserve-runtime-configs \
  --version v0.17.0 \
  --namespace kserve \
  --set kserve.llmisvcConfigs.enabled=true
```

### Method 3: Installation Scripts

#### Quick Install (All-in-One)

```bash
cd kserve

# Install dependencies + LLMInferenceService
./hack/setup/quick-install/llmisvc-full-install-helm.sh

# Or use with-manifest version (no clone needed, includes embedded manifests)
./hack/setup/quick-install/llmisvc-full-install-helm-with-manifest.sh
```

## Configuration Options

For detailed configuration options including gateway settings, resource limits, config templates, and multi-node configurations, see the [kserve-llmisvc-resources Helm Chart README](https://github.com/kserve/kserve/blob/release-0.17/charts/kserve-llmisvc-resources/README.md).
有关网关设置、资源限制、配置模板和多节点配置等详细配置选项, 请参阅 [kserve-llmisvc-resources Helm Chart README](https://github.com/kserve/kserve/blob/release-0.17/charts/kserve-llmisvc-resources/README.md).

### Test Installation

To test your LLMInferenceService installation with a sample, see the [Getting Started with LLMInferenceService](https://kserve.github.io/website/docs/getting-started/genai-first-llmisvc).
要使用示例测试您的 LLMInferenceService 安装, 请参阅 [LLMInferenceService 入门指南](https://kserve.github.io/website/docs/getting-started/genai-first-llmisvc).

## Uninstallation

### Helm

```bash
# Remove resources
helm uninstall kserve-runtime-configs -n kserve
helm uninstall kserve-llmisvc-resources -n kserve
helm uninstall kserve-llmisvc-crd -n kserve

# Remove namespace (if not shared)
kubectl delete namespace kserve
```

### Kustomize

```bash
# Remove LLMInferenceService
kubectl delete -k config/overlays/standalone/llmisvc
```

### Scripts

```bash
# Uninstall everything(dependencies + LLMIsvc) using helm quick install script from repo
./hack/setup/quick-install/llmisvc-full-install-helm.sh --uninstall

# Uninstall everything(dependencies + LLMIsvc) using kustomize quick install script
curl -fsSL https://github.com/kserve/kserve/releases/download/v0.17.0/llmisvc-full-install-with-manifests.sh | bash -s -- --uninstall

# Uninstall LLMIsvc by individual script
UNINSTALL=true ENABLE_LLMISVC=true ENABLE_KSERVE=false ./hack/setup/infra/manage.kserve-helm.sh
```

## Next Steps

- [Install LocalModel Controller](https://kserve.github.io/website/docs/install/localmodel-install) - For model caching
- [Getting Started with LLMInferenceService](https://kserve.github.io/website/docs/getting-started/genai-first-llmisvc) - Deploy your first generative AI model
- [LLMInferenceService Configuration Guide](https://kserve.github.io/website/docs/model-serving/generative-inference/llmisvc/llmisvc-configuration) - Advanced configuration
