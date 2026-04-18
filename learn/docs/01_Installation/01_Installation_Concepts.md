# Installation Concepts

This document explains the core concepts and architecture behind KServe's installation system, including component structure, deployment methods, and installation scripts.
本文档解释了 KServe 安装系统背后的核心概念和架构, 包括组件结构、部署方法和安装脚本.

## KServe Components Architecture
KServe 组件架构

KServe consists of three main components that can be deployed independently or in combination:
KServe 由三个主要组件构成, 这些组件可以独立部署, 也可以组合部署:

### Component Overview
组件概述

#### kserve

The core KServe controller that manages:
核心 KServe 控制器负责管理:

- **InferenceService CRD**: Defines ML model serving workloads
  **InferenceService CRD**: 定义机器学习模型服务工作负载

- **ServingRuntime CRD**: Configures model serving runtimes (TensorFlow, PyTorch, Triton, etc.)
  **ServingRuntime CRD**: 配置模型服务运行时(TensorFlow、PyTorch、Triton 等)

- **ClusterServingRuntime CRD**: Cluster-wide runtime configurations
  **ClusterServingRuntime CRD**: 集群范围的运行时配置

- **InferenceGraph CRD**: Multi-model inference pipelines
  **InferenceGraph CRD**: 多模型推理管道

- **TrainedModel CRD**: Model versioning and management
  **TrainedModel CRD**: 模型版本控制和管理

**Controller**: `kserve-controller-manager` handles reconciliation of InferenceService resources, webhook validation, and integration with Knative or raw Kubernetes deployments.
**控制器**: `kserve-controller-manager` 处理 InferenceService 资源的协调、webhook 验证以及与 Knative 或原始 Kubernetes 部署的集成.

#### llmisvc

The LLM Inference Service controller for generative AI workloads:
用于生成式 AI 工作负载的 LLM 推理服务控制器:

- **LLMInferenceService CRD**: Specialized resource for LLM serving
  **LLMInferenceService CRD**: LLM 服务的专用资源

- **LLMInferenceServiceConfig CRD**: Configuration templates for LLM deployments
  **LLMInferenceServiceConfig CRD**: LLM 部署的配置模板

**Controller**: `llmisvc-controller-manager` optimizes LLM deployments with features like KV-cache management, multi-node serving, and AI gateway integration.
**控制器**: `llmisvc-controller-manager` 通过 KV 缓存管理、多节点服务和 AI 网关集成等功能优化 LLM 部署.

#### localmodel (Optional)
本地模型(可选)

The LocalModel controller for efficient model caching:
用于高效模型缓存的 LocalModel 控制器:

- **LocalModelCache CRD**: Defines model caching policies
  **LocalModelCache CRD**: 定义模型缓存策略

- **LocalModelNode CRD**: Node-level model cache status
  **LocalModelNode CRD**: 节点级模型缓存状态

- **LocalModelNodeGroup CRD**: Logical grouping of cache nodes
  **LocalModelNodeGroup CRD**: 缓存节点的逻辑分组

**Components**:

- **Controller**: `kserve-localmodel-controller` manages cache lifecycle
  **控制器**:  `kserve-localmodel-controller` 管理缓存生命周期

- **Agent**: `kserve-localmodelnode-agent` runs as DaemonSet to handle local model caching
  **代理**:  `kserve-localmodelnode-agent` 作为 DaemonSet 运行, 用于处理本地模型缓存

> note
> LocalModel requires the **kserve** component to be installed and currently only supports **InferenceService** workloads. Support for **LLMInferenceService** is planned for future releases.
> LocalModel 需要安装 **kserve** 组件, 目前仅支持 **InferenceService** 工作负载. 未来版本计划支持 **LLMInferenceService**.
>

### Deployment Combinations
部署组合

| Combination <br/> 组合  | Use Case <br/> 用例                                                                            | Components <br/> 成分         |
| ----------------------- | ---------------------------------------------------------------------------------------------- | ----------------------------- |
| **KServe Only  KServe** | Predictive AI <br/> 预测性人工智能                                                             | kserve                        |
| **KServe + LLMIsvc**    | Predictive AI + Generative AI <br/> 预测型人工智能 + 生成型人工智能                            | kserve + llmisvc              |
| **Full Stack**          | Predictive AI + Generative AI + Model caching <br/> 预测性人工智能 + 生成式人工智能 + 模型缓存 | kserve + llmisvc + localmodel |

### Shared Resources

When deploying multiple components, certain resources are shared to avoid duplication:
部署多个组件时, 某些资源会共享以避免重复:

- **Certificates**: Webhook certificates managed by cert-manager
  **证书**: 由 cert-manager 管理的 Webhook 证书

- **ConfigMaps**: `inferenceservice-config` shared configuration
  **ConfigMaps**:  `inferenceservice-config` 共享配置

- **ClusterStorageContainers**: Storage provider configurations
  **集群存储容器**: 存储提供程序配置

The installation scripts automatically coordinate shared resource creation based on which components are being installed.
安装脚本会根据要安装的组件自动协调共享资源的创建.

## Kustomize Component-Based Architecture
自定义组件化架构

KServe uses [Kustomize components](https://kubectl.docs.kubernetes.io/guides/config_management/components/) for modular, composable deployments.
KServe 使用 [Kustomize 组件](https://kubectl.docs.kubernetes.io/guides/config_management/components/)实现模块化、可组合的部署.

### Directory Structure
目录结构

```bash
config/
├── base/                    # Shared resources (namespace, configmap, certificates)
├── components/              # Modular components
│   ├── kserve/              # KServe controller component
│   ├── llmisvc/             # LLMIsvc controller component
│   └── localmodel/          # LocalModel controller component
├── crd/                     # CustomResourceDefinitions
│   ├── full/                # CRDs with full validation
│   └── minimal/             # Lightweight CRDs without validation
├── overlays/                # Composition strategies
│   ├── standalone/          # Base + single component
│   ├── addons/              # Component only (no base)
│   └── all/                 # Base + all components
├── default/                 # KServe deployment
├── llmisvc/                 # LLMIsvc deployment
└── localmodels/             # LocalModel deployment
```

### Composition Strategies

**Standalone Overlays** (`overlays/standalone/`):

- Include `base` resources (namespace, shared configs)
  包含 `base` 资源(命名空间、共享配置)

- Include a single component
  包含单个组件

- Use for fresh installations
  用于全新安装

```yaml
# overlays/standalone/kserve/kustomization.yaml
namespace: kserve
resources:
- ../../../base
components:
- ../../../components/kserve
```

**Addon Overlays** (`overlays/addons/`):

- **Only** include the component (no base)
  **仅**包含组件(不含底座)

- Use for adding to existing installations
  用于添加到现有装置中

```yaml
# overlays/addons/llmisvc/kustomization.yaml
namespace: kserve
components:
- ../../../components/llmisvc
```

**All-in-One Overlay** (`overlays/all/`):

- Include base + all three components
  包括底座和所有三个组件

- Full-featured deployment
  功能齐全的部署

```yaml
# overlays/all/kustomization.yaml
namespace: kserve
resources:
- ../../base
components:
- ../../components/kserve
- ../../components/llmisvc
- ../../components/localmodel
```

## Helm Chart Structure

KServe provides 10 independent Helm charts organized by function:
KServe 提供 10 个按功能组织的独立 Helm Chart:

### Chart Organization  图表组织

#### CRD Charts (6 charts)

Install CustomResourceDefinitions with two variants per component:
每个组件安装两个变体的自定义资源定义:

| Chart                           | Description                                                        |
| ------------------------------- | ------------------------------------------------------------------ |
| `kserve-crd`                    | KServe CRDs with full validation <br/> KServe CRD 已完全验证       |
| `kserve-crd-minimal`            | KServe CRDs without validation <br/> 未经验证的 KServe CRD         |
| `kserve-llmisvc-crd`            | LLMIsvc CRDs with full validation <br/> LLMIsvc CRD 具有完整的验证 |
| `kserve-llmisvc-crd-minimal`    | LLMIsvc CRDs minimal <br/> LLMIsvc CRD 最小                        |
| `kserve-localmodel-crd`         | LocalModel CRDs with validation <br/> 带有验证的本地模型 CRD       |
| `kserve-localmodel-crd-minimal` | LocalModel CRDs minimal <br/> 本地模型 CRD 最小                    |

**Why two variants?**

- **Full**: Complete OpenAPI validation, better error messages, larger size
  **完整版**: 完整的 OpenAPI 验证、更清晰的错误信息、更大的文件大小

- **Minimal**: Faster installation, smaller memory footprint, less validation
  **极简版**: 安装速度更快、内存占用更小、验证次数更少

#### Resources Charts (4 charts)

Install controllers, RBAC, webhooks, and shared resources:
安装控制器、基于角色的访问控制 (RBAC)、Webhook 和共享资源:

| Chart                         | Description                             | Dependencies <br/> 依赖关系      |
| ----------------------------- | --------------------------------------- | -------------------------------- |
| `kserve-resources`            | KServe controller, webhooks, ConfigMap  | Requires `kserve-crd`            |
| `kserve-llmisvc-resources`    | LLMIsvc controller, webhooks, ConfigMap | Requires `kserve-llmisvc-crd`    |
| `kserve-localmodel-resources` | LocalModel controller + agent DaemonSet | Requires `kserve-localmodel-crd` |
| `kserve-runtime-configs`      | ClusterServingRuntimes, LLMIsvcConfigs  | Requires `kserve-crd`            |

### Values Hierarchy

Helm values are composed from shared and component-specific sections:
Helm 值由共享部分和组件特定部分组成:

```yaml
# charts/_common/common-sections.yaml
# Shared by all resource charts
kserve:
  version: v0.17.0
  createSharedResources: true
  agent: {...}
  storage: {...}
  servingruntime: {...}
  # ... 16 shared sections
```

```yaml
# charts/_common/kserve-resources-specific.yaml
# KServe-specific values
kserve:
  controller:
    image: kserve/kserve-controller
    deploymentMode: Knative
    gateway: {...}
```

```bash
# Auto-generated values.yaml = common + specific
yq eval-all '. as $item ireduce ({}; . * $item)' common-sections.yaml kserve-resources-specific.yaml > kserve-resources/values.yaml
```

**Benefits of this approach:
这种方法的优点:

- **DRY**: Shared sections defined once
  **DRY 原则**: 共享部分只需定义一次.

- **Consistency**: All charts use same values structure
  **一致性**: 所有图表均使用相同的值结构

- **Maintainability**: Update shared config in one place
  **可维护性**: 在一个地方更新共享配置

### Base + Patch System

Helm charts use a sophisticated base + patch approach:
Helm Charts 采用了一种复杂的基础 + 补丁方法:

1. **Generate Base**: Run `kustomize build` to create base manifests
   **生成基础清单**: 运行 `kustomize build` 创建基础清单

```bash
kustomize build config/components/kserve > charts/kserve-resources/files/kserve/resources.yaml
```

2. **Create Patches**: Define Helm-specific overrides
   **创建补丁**: 定义 Helm 特有的覆盖规则

```yaml
# files/kserve/deployment-patch.yaml
kind: Deployment
metadata:
  name: kserve-controller-manager
spec:
  template:
    spec:
      containers:
      - name: manager
        image: "{{ .Values.kserve.controller.image }}:{{ .Values.kserve.controller.tag }}"
        resources: {{ toYaml .Values.kserve.controller.resources | nindent 12 }}
```

3. **Render with Deep Merge**: Template helper merges base + patches
   **使用深度合并渲染**: 模板助手合并基础和补丁

```yaml
{{- include "kserve-common.renderMultiResourceWithPatches" (dict
  "baseFile" "files/kserve/resources.yaml"
  "patchGlob" "files/kserve/*-patch.yaml"
  "certName" "serving-cert"
  "context" .) -}}
```


**Deep Merge Logic**:
深度合并逻辑:

- Recursively merges dictionaries
  递归合并字典

- Smart array merging by `name` field (containers, env vars)
  按 `name` 字段(容器、环境变量)进行智能数组合并

- Preserves Kustomize structure while enabling Helm parameterization
  保留 Kustomize 结构, 同时启用 Helm 参数化

## Installation Script Architecture
安装脚本架构

The `hack/setup` directory provides a comprehensive installation framework:
`hack/setup` 目录提供了一个全面的安装框架:

### Directory Organization

```bash
hack/setup/
├── common.sh                  # Shared utilities
├── global-vars.env            # Environment variables
├── SCRIPT_GUIDELINES.md       # Script standards
├── cli/                       # CLI tool installers
│   ├── install-helm.sh
│   ├── install-kustomize.sh
│   ├── install-kind.sh
│   ├── install-yq.sh
│   └── install-uv.sh
├── infra/                     # Infrastructure components
│   ├── manage.cert-manager-helm.sh
│   ├── manage.istio-helm.sh
│   ├── manage.keda-helm.sh
│   ├── manage.kserve-helm.sh
│   ├── manage.kserve-kustomize.sh
│   ├── knative/
│   ├── gateway-api/
│   └── ...
├── quick-install/             # Generated installation scripts
│   ├── definitions/           # YAML definitions
│   └── *.sh                   # Generated scripts
└── scripts/                   # Automation tools
    ├── validate-install-scripts.py
    └── install-script-generator/
```

### Common Utility Library (common.sh)
通用实用程序库(common.sh)

All scripts source `common.sh` for shared functionality:
所有脚本都调用 `common.sh` 来实现共享功能:

**System Detection**:
系统检测:

- `detect_os()` - Identifies Linux/Darwin
  `detect_os()` - 识别 Linux/Darwin

- `detect_arch()` - Maps architecture (x86_64, aarch64)
  `detect_arch()` - 映射架构(x86_64、aarch64)

- `detect_platform()` - Detects Kind, Minikube, OpenShift, or Kubernetes
  `detect_platform()` - 检测 Kind、Minikube、OpenShift 或 Kubernetes

**Kubernetes Utilities**:
Kubernetes 工具:

- `wait_for_pods()` - Wait for pods to be created and ready
  `wait_for_pods()` - 等待 Pod 创建完成并准备就绪

- `wait_for_deployment()` - Wait for deployment availability
  `wait_for_deployment()` - 等待部署可用

- `wait_for_crd()` - Wait for CRD establishment
  `wait_for_crd()` - 等待 CRD 建立

- `update_isvc_config()` - Update InferenceService ConfigMap with jq
  `update_isvc_config()` - 使用 jq 更新 InferenceService ConfigMap

**Logging**:
日志记录:

- `log_info()`, `log_success()`, `log_error()`, `log_warning()` - Color-coded output
  颜色编码的输出

**Example Script Structure**:
脚本结构示例:

```bash
#!/bin/bash
# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

install() {
  log_info "Installing cert-manager..."
  helm repo add jetstack https://charts.jetstack.io
  helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set crds.enabled=true

  wait_for_pods "cert-manager" "app.kubernetes.io/instance=cert-manager" 300
  log_success "cert-manager installed successfully"
}

uninstall() {
  log_info "Uninstalling cert-manager..."
  helm uninstall cert-manager -n cert-manager
  kubectl delete namespace cert-manager --wait=true
}

# Main execution
if [ "$UNINSTALL" = true ]; then uninstall; exit 0; fi
install
```

### CLI Tool Installation

Scripts in `cli/` handle prerequisite tool installation:
`cli/` 中的脚本处理必备工具的安装:

**Pattern**:

1. Check if already installed and at correct version
   检查是否已安装且版本正确

2. Detect OS and architecture
   检测操作系统和架构

3. Download from official source
   从官方来源下载

4. Verify and install to `$BIN_DIR`
   验证并安装到 `$BIN_DIR`

5. Add to `$PATH`
   添加到 `$PATH`

**Example**:

```bash
# Install Helm
./hack/setup/cli/install-helm.sh

# Install with specific version
HELM_VERSION=v3.13.0 ./hack/setup/cli/install-helm.sh
```

### Infrastructure Management
基础设施管理

Scripts in `infra/` manage Kubernetes components:
`infra/` 管理 Kubernetes 组件中的脚本:

**Capabilities**:

- Install, reinstall, uninstall modes
  安装、重新安装、卸载模式

- Version management from `kserve-deps.env`
  来自 `kserve-deps.env` 版本管理

- Platform-specific adaptations
  平台特定适配

- Custom Helm/Kustomize arguments via env vars
  通过环境变量自定义 Helm/Kustomize 参数

**Examples**:

```bash
# Install Istio
./hack/setup/infra/manage.istio-helm.sh

# Reinstall with custom args
REINSTALL=true \
ISTIOD_EXTRA_ARGS="--set resources.limits.cpu=500m" \
./hack/setup/infra/manage.istio-helm.sh

# Uninstall
UNINSTALL=true ./hack/setup/infra/manage.istio-helm.sh
```

**Generation Steps**:
生成步骤:

1. **Parse Definition**: Load YAML with tools, components, and config
   解析定义: 加载包含工具、组件和配置的 YAML 文件

2. **Process Components**: Find and extract functions from scripts
   流程组件: 从脚本中查找并提取函数

3. **Embed Content**: Optionally embed manifests and templates
   嵌入内容: 可选择嵌入清单和模板

4. **Build Script**: Combine functions, variables, and logic
   构建脚本: 组合函数、变量和逻辑

5. **Output**: Write standalone executable script
   输出: 编写独立可执行脚本

**Example Definition**:

```yaml
# quick-install/definitions/kserve-standard-mode-full-install.definition
DESCRIPTION: Install KServe Standard Mode using Helm
RELEASE: true

TOOLS:
  - helm
  - kustomize
  - yq

COMPONENTS:
  - name: cert-manager-helm
  - name: istio-helm
  - name: kserve-helm
    env:
      DEPLOYMENT_MODE: Standard
      ENABLE_KSERVE: true
      ENABLE_LLMISVC: false
```

## Summary

KServe's installation system provides multiple deployment methods with different trade-offs:
KServe 的安装系统提供了多种部署方法, 每种方法各有优缺点:

**Key Takeaways**:
要点总结:

- **3 Components**: kserve (mandatory), llmisvc (mandatory), localmodel (optional)
  **3 个组件**: kserve(必需)、llmisvc(必需)、localmodel(可选)

- **Flexible Deployment**: Kustomize components or Helm charts
  **灵活部署**: 自定义组件或 Helm Charts

- **Automated Scripts**: Generated from definitions or individual scripts
  **自动脚本**: 由定义或单个脚本生成

- **Shared Foundation**: common.sh library and global configuration
  **共享基础**: common.sh 库和全局配置

- **Production Ready**: Multiple deployment modes, customization options, lifecycle management
  **生产就绪**: 多种部署模式、自定义选项、生命周期管理

For detailed installation instructions, see the [Quick Start Guide](https://kserve.github.io/website/docs/getting-started/quickstart-guide).
有关详细安装说明, 请参阅[快速入门指南](https://kserve.github.io/website/docs/getting-started/quickstart-guide).
