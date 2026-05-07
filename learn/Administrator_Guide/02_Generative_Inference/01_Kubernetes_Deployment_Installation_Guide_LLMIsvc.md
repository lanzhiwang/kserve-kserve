# Kubernetes Deployment Installation Guide - LLMIsvc

* https://kserve.github.io/website/docs/0.16/admin-guide/kubernetes-deployment-llmisv

LLMInferenceService is KServe's dedicated solution for **Generative AI inference workloads**, providing advanced features like:
LLMInferenceService 是 KServe 专为**生成式 AI 推理工作负载**打造的解决方案, 提供以下高级功能:

- **Intelligent Routing**: KV cache-aware scheduling, prefill-decode separation
  **智能路由**: 基于键值缓存的调度, 预填充-解码分离

- **Multi-Node Orchestration**: Data parallelism, expert parallelism via LeaderWorkerSet
  **多节点编排**: 数据并行、通过 LeaderWorkerSet 实现专家并行

- **Gateway API Native**: Built on Kubernetes Gateway API with Inference Extension
  **Gateway API Native**: 基于 Kubernetes Gateway API 构建, 带有推理扩展.

- **Autoscaling**: Integration with KEDA for custom metrics-based scaling
  **自动扩缩容**: 与 KEDA 集成, 实现基于自定义指标的扩缩容.

> note
> LLMInferenceService is designed specifically for **Generative AI** workloads (LLMs). For **Predictive AI** workloads, use [InferenceService](https://kserve.github.io/website/docs/0.16/admin-guide/kubernetes-deployment).
> LLMInferenceService 专为**生成式人工智能**工作负载(LLM)而设计. 对于**预测式人工智能**工作负载, 请使用 [InferenceService](https://kserve.github.io/website/docs/0.16/admin-guide/kubernetes-deployment).
>

## Installation Requirements

### Minimum Requirements

- **Kubernetes**: Version 1.32+

- **Cert Manager**: Version 1.18.0+

- **Gateway API**: Version 1.2.1

- **Gateway API Inference Extension (GIE)**: Version 0.3.0

- **Gateway Provider**: Envoy Gateway v1.5.0+

- **LeaderWorkerSet**: Version 0.6.2+ (for multi-node deployments)

> tip
> For detailed dependency information and step-by-step installation, see [LLMInferenceService Dependencies](https://kserve.github.io/website/docs/0.16/model-serving/generative-inference/llmisvc/llmisvc-dependencies).
> 有关详细的依赖项信息和分步安装, 请参阅 [LLMInferenceService 依赖项](https://kserve.github.io/website/docs/0.16/model-serving/generative-inference/llmisvc/llmisvc-dependencies).
>

## Prerequisites

- `kubectl` configured to access your cluster

- Cluster admin permissions

- `helm` v3+ installed

---

The fastest way to get started with LLMInferenceService is using the quick install script. Please refer to the [Quickstart Guide](https://kserve.github.io/website/docs/0.16/getting-started/quickstart-guide).
使用 LLMInferenceService 最快的入门方法是使用快速安装脚本. 请参阅[快速入门指南](https://kserve.github.io/website/docs/0.16/getting-started/quickstart-guide).

## Installation

KServe provides installation scripts for infrastructure-related dependencies and CLI tools, with versions managed via [a central place](https://github.com/kserve/kserve/blob/master/kserve-deps.env). Here, we will demonstrate how to use these scripts to install the components required for LLMInferenceService. Each component mentioned here can be installed according to your own environment. For example, you can use the GatewayClass you are already using, and you can choose the Gateway API provider that fits your environment
KServe 提供基础设施相关依赖项和 CLI 工具的安装脚本, [版本统一](https://github.com/kserve/kserve/blob/master/kserve-deps.env)管理. 本文将演示如何使用这些脚本安装 LLMInferenceService 所需的组件. 您可以根据自身环境安装此处提到的每个组件. 例如, 您可以使用已在使用的 GatewayClass, 也可以选择适合您环境的 Gateway API 提供程序.

### 1. Clone KServe Repository

```bash
git clone https://github.com/kserve/kserve.git
cd kserve/hack/setup
```

### 2. Install Infrastructure Components
安装基础架构组件

Install each component in the following order. Each script supports `--install` (default), `--uninstall`, and `--reinstall` options.
请按以下顺序安装每个组件. 每个脚本都支持 `--install` (默认)、 `--uninstall` 和 `--reinstall` 选项.

#### External Load Balancer (Local Clusters Only)
外部负载均衡器(仅限本地集群)

For local development on Kind or Minikube:
用于在 Kind 或 Minikube 上进行本地开发:

```bash
infra/external-lb/manage.external-lb.sh
```

> note
> Skip this step if you're using a cloud provider (AWS, GCP, Azure) that provides native LoadBalancer support.
> 如果您使用的是提供原生负载均衡器支持的云提供商(AWS、GCP、Azure), 请跳过此步骤.
>

#### Cert Manager

```bash
# infra/manage.cert-manager.sh
infra/manage.cert-manager-helm.sh
```

> note
> Cert Manager is required for webhook certificates and LeaderWorkerSet operator. It's essential for production-grade installation.
> 证书管理器是 webhook 证书和 LeaderWorkerSet 操作符所必需的. 它对于生产级安装至关重要.
>

#### Gateway API & Inference Extension CRDs

Installs both Gateway API CRDs and the Inference Extension (GIE):
安装网关 API CRD 和推理扩展 ​​(GIE):

```bash
infra/gateway-api/manage.gateway-api-crd.sh
```

#### Envoy Gateway

The Gateway API provider for routing
用于路由的网关 API 提供程序

```bash
infra/manage.envoy-gateway.sh
```

#### Envoy AI Gateway

The Gateway API Extension provider(GIE) for routing
用于路由的网关 API 扩展提供程序 (GIE)

```bash
infra/manage.envoy-ai-gateway.sh
```

#### LeaderWorkerSet Operator

Required for multi-node deployments (Data/Expert Parallelism):
多节点部署(数据/专家并行)所需:

```bash
infra/manage.lws-operator.sh
```

#### GatewayClass

```bash
infra/gateway-api/managed.gateway-api-gwclass.sh
```

#### Gateway Instance

```bash
infra/gateway-api/managed.gateway-api-gw.sh
```

#### Install KServe Components

Choose your installation method based on your needs:
根据您的需求选择安装方式:

##### LLMIsvc Only (Helm)

Install only LLMInferenceService CRDs and controller using helm:
仅使用 Helm 安装 LLMInferenceService CRD 和控制器:

```bash
LLMISVC=true infra/manage.kserve-helm.sh
```

> success
> This installs only the LLMInferenceService components. InferenceService is not included.
> 此命令仅安装 LLMInferenceService 组件, 不包含 InferenceService.
>

##### LLMIsvc Only (Kustomize)

Install only LLMInferenceService CRDs and controller using kustomize:
仅使用 kustomize 安装 LLMInferenceService CRD 和控制器:

```bash
LLMISVC=true infra/manage.kserve-kustomize.sh
```

> note
> This provides more granular control over the installation compared to Helm.
> 与 Helm 相比, 这可以提供更精细的安装控制.
>

##### Full KServe (Helm)

Install both InferenceService and LLMInferenceService:
安装 InferenceService 和 LLMInferenceService:

```bash
infra/manage.kserve-helm.sh
```

> info
> This installs the complete KServe stack including both InferenceService (for Predictive AI) and LLMInferenceService (for Generative AI).
> 这将安装完整的 KServe 堆栈, 包括 InferenceService(用于预测性 AI)和 LLMInferenceService(用于生成性 AI).
>

##### Full KServe (Kustomize)

Install both InferenceService and LLMInferenceService using kustomize:
使用 kustomize 安装 InferenceService 和 LLMInferenceService:

```bash
infra/manage.kserve-kustomize.sh
```

> info
> This installs the complete KServe stack with kustomize for greater customization flexibility.
> 这将安装完整的 KServe 堆栈, 并启用 kustomize 以实现更大的定制灵活性.
>

## Next Steps

Now that LLMInferenceService is installed, you can:
LLMInferenceService 安装完成后, 您可以:

1. **Deploy Your First LLM**: Follow the [Quick Start Guide](https://kserve.github.io/website/docs/0.16/getting-started/genai-first-isvc)
  部署您的第一个 LLM: 请遵循快速入门指南

2. **Understand the Architecture**: Read [LLMInferenceService Overview](https://kserve.github.io/website/docs/0.16/model-serving/generative-inference/llmisvc/llmisvc-overview)
  了解架构: 阅读 LLMInferenceService 概述

3. **Explore Configuration Options**: Check [LLMInferenceService Configuration](https://kserve.github.io/website/docs/0.16/model-serving/generative-inference/llmisvc/llmisvc-configuration)
  查看配置选项: 检查 LLMInferenceService 配置

4. **Learn Advanced Features**:

  - [Multi-Node Deployments](https://github.com/kserve/kserve/tree/master/docs/samples/llmisvc/dp-ep) - Data/Expert parallelism
    多节点部署 - 数据/专家并行性

  - [Prefill-Decode Separation](https://kserve.github.io/website/docs/0.16/concepts/architecture/control-plane-llmisvc#prefill-decode-separation) - Performance optimization
    预填充-解码分离 - 性能优化
