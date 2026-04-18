# Required Dependencies

This document outlines the infrastructure dependencies required for KServe installation based on your deployment mode.
本文档概述了根据您的部署模式, KServe 安装所需的基础设施依赖项.

## Knative Mode Dependencies

Knative mode provides serverless deployment with automatic scaling and traffic management.
Knative 模式提供无服务器部署, 并具有自动扩展和流量管理功能.

### Required Components  所需组件

| Component               | Version | Purpose                                                               |
| ----------------------- | ------- | --------------------------------------------------------------------- |
| **cert-manager**        | v1.17.0 | TLS certificate management for webhooks <br/> Webhook 的 TLS 证书管理 |
| **Istio**               | 1.27.1  | Service mesh and ingress gateway <br/> 服务网格和入口网关             |
| **istio-ingress-class** | -       | Istio IngressClass configuration <br/> Istio IngressClass 配置        |
| **Knative Operator**    | v1.21.1 | Serverless platform operator                                          |
| **Knative Serving**     | 1.21.1  | Serverless serving runtime                                            |

### Required CLI Tools

- **helm** - Kubernetes package manager
- **kustomize** - Kubernetes configuration management
- **yq** - YAML processor
- **kubectl** - Kubernetes CLI

## Cloning the Repository

Most installation methods require cloning the KServe repository to access installation scripts and Kustomize configurations.
大多数安装方法需要克隆 KServe 存储库才能访问安装脚本和 Kustomize 配置.

```bash
git clone https://github.com/kserve/kserve.git
cd kserve
```

> tip
> You only need to clone the repository once. All installation guides in this section assume you're in the `kserve/` directory.
> 您只需克隆一次代码库. 本节中的所有安装指南均假设您位于 `kserve/` 目录下.
>

### Installation

Use the pre-generated dependency installation script:
使用预先生成的依赖项安装脚本:

```bash
# Install dependencies for Knative mode
curl -fsSL https://github.com/kserve/kserve/releases/download/v0.17.0/kserve-knative-mode-dependency-install.sh | bash
```

Or install components individually:
或者单独安装组件:

```bash
# cert-manager
./hack/setup/infra/manage.cert-manager-helm.sh

# Istio (3 components)
./hack/setup/infra/manage.istio-helm.sh

# Istio IngressClass
./hack/setup/infra/manage.istio-ingress-class.sh

# Knative Operator
./hack/setup/infra/knative/manage.knative-operator-helm.sh
```

## Standard Mode Dependencies
标准模式依赖项

Standard mode uses raw Kubernetes deployments without serverless features.
标准模式使用原始的 Kubernetes 部署, 不包含无服务器功能.

### Required Components

| Component        | Version  | Purpose                                                               |
| ---------------- | -------- | --------------------------------------------------------------------- |
| **cert-manager** | v1.17.0+ | TLS certificate management for webhooks <br/> Webhook 的 TLS 证书管理 |

### Required CLI Tools

- **helm** - Kubernetes package manager
- **yq** - YAML processor
- **kubectl** - Kubernetes CLI

### Installation

```bash
# Install dependencies for Standard mode
 curl -fsSL https://github.com/kserve/kserve/releases/download/v0.17.0/kserve-standard-mode-dependency-install.sh | bash
```

Or install cert-manager directly:
或者直接安装 cert-manager:

```bash
./hack/setup/infra/manage.cert-manager-helm.sh
```

## LLMIsvc Dependencies

LLMIsvc mode is optimized for large language model serving with Gateway API integration.
LLMIsvc 模式针对大型语言模型服务进行了优化, 并集成了 Gateway API.

### Required Components  所需组件

| Component                      | Purpose                                                                     |
| ------------------------------ | --------------------------------------------------------------------------- |
| **External LB**                | Load balancer for Kind/Minikube <br/> Kind/Minikube 的负载均衡器            |
| **cert-manager**               | TLS certificate management <br/> TLS 证书管理                               |
| **Gateway API Extension CRDs** | Inference-specific Gateway API extensions <br/> 推理专用网关 API 扩展       |
| **Gateway API CRDs**           | Core Gateway API resources <br/> 核心网关 API 资源                          |
| **Envoy Gateway**              | Gateway API implementation                                                  |
| **Envoy AI Gateway**           | AI-specific gateway extensions                                              |
| **Gateway API GatewayClass**   | Gateway class configuration                                                 |
| **Gateway API Gateway**        | Gateway resource instances                                                  |
| **LWS Operator**               | LeaderWorkerSet for multi-node serving <br/> LeaderWorkerSet 用于多节点服务 |

### Required CLI Tools

- **helm** - Kubernetes package manager
- **yq** - YAML processor
- **kubectl** - Kubernetes CLI

### Installation

```bash
# Install dependencies for LLMIsvc mode
curl -fsSL https://github.com/kserve/kserve/releases/download/v0.17.0/llmisvc-dependency-install.sh | bash
```

Or install components individually:
或者单独安装组件:

```bash
# External load balancer (platform-specific)
./hack/setup/infra/external-lb/manage.external-lb.sh

# cert-manager
./hack/setup/infra/manage.cert-manager-helm.sh

# Gateway API Extension CRDs
./hack/setup/infra/gateway-api/manage.gateway-api-extension-crd.sh

# Gateway API CRDs
./hack/setup/infra/gateway-api/manage.gateway-api-crd.sh

# Envoy Gateway
./hack/setup/infra/manage.envoy-gateway-helm.sh

# Envoy AI Gateway
./hack/setup/infra/manage.envoy-ai-gateway-helm.sh

# Gateway API GatewayClass
./hack/setup/infra/gateway-api/manage.gateway-api-gwclass.sh

# Gateway API Gateway
./hack/setup/infra/gateway-api/manage.gateway-api-gw.sh

# LWS Operator
./hack/setup/infra/manage.lws-operator.sh
```

## Optional Dependencies

### KEDA (Event-Driven Autoscaling)
KEDA(事件驱动自动扩缩容)

KEDA enables event-driven autoscaling based on custom metrics and external triggers.
KEDA 支持基于自定义指标和外部触发器的事件驱动型自动扩缩容.

**When to use**:
何时使用:

- Need autoscaling based on custom metrics
  需要基于自定义指标的自动扩缩容

- Want event-driven workload triggers
  希望采用事件驱动的工作负载触发器

- Require integration with external event sources
  需要与外部事件源集成

**Components**:

| Component                  | Purpose                                                                 |
| -------------------------- | ----------------------------------------------------------------------- |
| **KEDA**                   | Kubernetes Event-Driven Autoscaling <br/> Kubernetes 事件驱动自动扩缩容 |
| **KEDA OTEL Addon**        | OpenTelemetry metrics integration <br/> OpenTelemetry 指标集成          |
| **OpenTelemetry Operator** | Observability and tracing <br/> 可观测性和可追踪性                      |

**Installation**:

```bash
# Install KEDA and dependencies
curl -fsSL https://github.com/kserve/kserve/releases/download/v0.17.0/keda-dependency-install.sh | bash
```

Or individually:

```bash
# OpenTelemetry Operator
./hack/setup/infra/manage.opentelemetry-helm.sh

# KEDA
./hack/setup/infra/manage.keda-helm.sh

# KEDA OTEL Addon
./hack/setup/infra/manage.keda-otel-addon-helm.sh
```

## Custom Dependency Scripts
自定义依赖脚本

You can create custom installation scripts for specific dependency combinations.
您可以为特定的依赖项组合创建自定义安装脚本.

### Using Make Target

The easiest way to regenerate all quick-install scripts:
重新生成所有快速安装脚本的最简单方法:

```bash
# Generate all quick-install scripts
make generate-quick-install-scripts
```

This processes all definition files in `hack/setup/quick-install/definitions/` and creates standalone installation scripts.
此操作会处理 `hack/setup/quick-install/definitions/` 中的所有定义文件, 并创建独立的安装脚本.

### Generating from Specific Definition
从特定定义生成

Generate a script from a specific definition file:
根据指定的定义文件生成脚本:

```bash
python hack/setup/scripts/install-script-generator/generator.py \
  hack/setup/quick-install/definitions/kserve-knative/kserve-knative-mode-dependency-install.definition
```

### Creating Custom Definitions

Create your own dependency combination by writing a YAML definition file:
通过编写 YAML 定义文件来创建您自己的依赖关系组合:

```yaml
# my-custom-dependencies.definition
DESCRIPTION: Custom KServe dependencies for my environment
RELEASE: true

# Required CLI tools
TOOLS:
  - helm
  - kustomize
  - yq

# Optional: Include existing definitions
INCLUDE_DEFINITIONS:
  - ./kserve-standard-mode-dependency-install.definition

# Optional: Set global environment variables
GLOBAL_ENV:
  ISTIO_VERSION: "1.27.1"

# Components to install
COMPONENTS:
  - name: cert-manager
  - name: istio
    env:
      ISTIOD_EXTRA_ARGS: "--set resources.limits.cpu=500m"
  - name: keda
```

**Generate the script**:

```bash
mkdir /tmp/test
python hack/setup/scripts/install-script-generator/generator.py \
  my-custom-dependencies.definition \
  /tmp/test/
```

**Run the generated script**:

```bash
# Install
/tmp/test//my-custom-dependencies-helm.sh

# Uninstall
/tmp/test/my-custom-dependencies-helm.sh --uninstall
```

### Definition File Structure
定义文件结构

**Required Fields**:
必填字段:

- `DESCRIPTION`: Human-readable description
  `DESCRIPTION`: 人类可读的描述

- `COMPONENTS`: List of components to install
  `COMPONENTS`: 待安装组件列表

**Optional Fields**:
可选字段:

- `TOOLS`: Required CLI tools to verify
  `TOOLS`: 验证所需的 CLI 工具

- `INCLUDE_DEFINITIONS`: Import other definition files
  `INCLUDE_DEFINITIONS`: 导入其他定义文件

- `GLOBAL_ENV`: Environment variables for all components
  `GLOBAL_ENV`: 所有组件的环境变量

**Component Structure**:

```yaml
COMPONENTS:
  - name: component-name         # Matches script in hack/setup/infra/
    env:                         # Optional environment variables
      VAR1: value1
      VAR2: value2
```

**Composition with INCLUDE_DEFINITIONS**:
使用 INCLUDE_DEFINITIONS 进行组合:

- Include other definition files to build on existing combinations
  包含其他定义文件, 以便在现有组合的基础上进行构建

- Last-wins strategy: Later components override earlier ones
  后发制人策略: 后发组件会覆盖前发组件.

- Circular dependency detection prevents infinite loops
  循环依赖检测可以防止无限循环.

## Dependency Matrix

Quick reference for deployment modes:
部署模式快速参考:

| Dependency    | Knative Mode | Standard Mode | LLMIsvc Mode       |
| ------------- | ------------ | ------------- | ------------------ |
| cert-manager  | ✅ Required   | ✅ Required    | ✅ Required         |
| Istio         | ✅ Required   | ❌ Not needed  | ❌ Not needed       |
| Knative       | ✅ Required   | ❌ Not needed  | ❌ Not needed       |
| Envoy Gateway | ❌ Not needed | ❌ Not needed  | ✅ Required         |
| Gateway API   | ❌ Not needed | ❌ Not needed  | ✅ Required         |
| LWS Operator  | ❌ Not needed | ❌ Not needed  | ✅ Required         |
| KEDA          | ⚙️ Optional   | ⚙️ Optional    | ⚙️ Optional         |
| External LB   | ⚙️ Optional   | ⚙️ Optional    | ✅ Required (local) |

## Next Steps  后续步骤

After installing dependencies, proceed to install KServe components:
安装完依赖项后, 继续安装 KServe 组件:

- [Install KServe Controller](https://kserve.github.io/website/docs/install/kserve-install)
- [Install LLMIsvc Controller](https://kserve.github.io/website/docs/install/llmisvc-install)
- [Install LocalModel Controller](https://kserve.github.io/website/docs/install/localmodel-install)
