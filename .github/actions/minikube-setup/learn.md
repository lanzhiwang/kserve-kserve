这个 `minikube-setup/action.yml` 是整个 E2E(端到端)测试的"地基".
在 CI 中, 我们不能仅仅测试代码逻辑, 还必须在真实的 K8s 集群中验证控制器(Controller)、CRD 和 Webhook 是否正常工作.

---

### 1. 为 `action.yml` 添加详细注释

这是一个 Composite Action. 它通过封装 `kubectl` 安装、`minikube` 启动和健康检查, 为后续的测试步骤提供一个完全就绪的 Kubernetes 环境.

```yaml
# Action 的显示名称, 在 GitHub Actions 运行记录中可见
name: "Minikube setup action"
# 功能描述: 在 GitHub Action 运行器(Runner)上设置并启动 minikube
description: "Sets up minikube on the github runner"

# 定义输入参数, 增强了集群部署的灵活性
inputs:
  # Minikube 集群启动的节点数量(支持模拟多节点集群)
  nodes:
    description: "Number of nodes to start minikube with"
    required: false
    default: "1"

  # Minikube 使用的驱动程序. 在 GitHub Ubuntu Runner 上, 'none' 性能最好, 因为它直接在宿主机运行
  driver:
    description: "Driver to use for minikube"
    required: false
    default: "none"

  # 传递给 minikube start 的额外自定义参数(如: --container-runtime=containerd)
  start-args:
    description: "Additional arguments to pass to minikube start"
    required: false
    default: ""

runs:
  # 声明这是一个复合 Action
  using: "composite"
  steps:
    # 第一步: 安装指定版本的 kubectl 命令行工具
    - name: Install kubectl
      uses: azure/setup-kubectl@v4.0.0
      with:
        # 锁定 K8s 版本, 确保与集群版本完全匹配, 避免 API 兼容性问题
        version: "v1.34.4"

    # 第二步: 启动 Minikube
    # 使用了社区公认最稳定的 setup-minikube action
    - name: Setup Minikube
      uses: medyagh/setup-minikube@latest
      with:
        minikube-version: "1.38.1"
        kubernetes-version: "v1.34.4"
        driver: ${{ inputs.driver }}
        # wait: "all" 表示等待所有系统组件(如 apiserver, scheduler)完全 Ready 才继续
        wait: "all"
        cpus: "max"
        memory: "max"
        # --wait-timeout=6m0s: 给予足够的启动时间, 防止在资源紧张时超时
        # --nodes: 允许根据测试需要启动多节点
        start-args: --wait-timeout=6m0s --nodes=${{ inputs.nodes }} ${{ inputs.start-args }}

    # 第三步: 冒烟测试/健康检查
    - name: Check Kubernetes pods
      shell: bash
      # 打印 kube-system 命名空间下的所有 Pod, 方便在日志中确认集群是否真的健康
      run: kubectl get pods -n kube-system

```

---

### 2. 核心技术点解析(高级开发视角)

1. Driver: "none" 的妙用:

  在普通的本地电脑上, Minikube 通常在 Docker 或虚拟机里运行. 但在 GitHub Actions 的 Ubuntu Runner 中, Runner 本身就是一个虚拟机. 使用 `driver: none` 意味着 K8s 组件直接作为进程/容器运行在 Runner 的宿主机上.

    * 优点: 省去了虚拟化嵌套的开销, 速度最快, 内存占用最少.

    * 注意: 这需要 `sudo` 权限(Action 内部已处理).

2. 版本对齐 (Version Pinning):

  脚本中严格锁定了 `kubectl v1.34.4`、`kubernetes v1.34.4` 和 `minikube 1.38.1`.

    * 在大型开源项目中, 这是为了环境幂等性. 不管什么时候跑 CI, 环境都是一致的, 避免因为 `latest` 版本更新导致流水线莫名其妙挂掉.

3. 资源压榨 (`max`):

  `cpus: "max"` 和 `memory: "max"`. GitHub 标准 Runner 只有 2 核 7G 内存, 对于 KServe 这种需要运行 Istio、Knative 和多个控制器的项目来说, 资源非常吃紧. 必须全量分配才能保证集群不崩溃.

---

### 3. 使用场景

* E2E (End-to-End) 集成测试:

  这是最主要场景. 当开发者提交 PR 时, CI 需要启动一个真实的 K8s, 把刚才构建的 Controller 部署进去, 然后创建一个 `InferenceService` 资源, 观察 Controller 是否能正确拉起 Pod.

* Helm Chart 验证:

  验证 Helm 安装脚本是否能在真实集群中成功渲染并部署.

* Webhook 验证:

  K8s 的准入控制(Admission Webhooks)必须在真实集群环境下才能测试其拦截逻辑.

---

### 4. 使用方法

这个 Action 通常紧跟在 `free-up-disk-space` 之后(因为启动 K8s 很占磁盘), 并且在 `kserve-dep-setup` 之前.

#### 示例: 在 `.github/workflows/e2e-test.yml` 中引用

```yaml
jobs:
  integration-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      # 1. 腾出空间, 否则启动集群时会报磁盘空间不足
      - name: Free up disk
        uses: ./.github/actions/free-up-disk-space

      # 2. 启动集群 (调用本 Action)
      - name: Setup Kubernetes
        uses: ./.github/actions/minikube-setup
        with:
          # 单节点即可满足大多数测试
          nodes: 1
          # 如果需要启用特定功能, 可以在这里传参
          start-args: "--container-runtime=containerd"

      # 3. 安装项目依赖 (Istio, Knative 等)
      - name: Setup Deps
        uses: ./.github/actions/kserve-dep-setup

      # 4. 运行测试命令
      - name: Run Go E2E Tests
        run: go test -v ./test/e2e/...
```

### 运维专家建议:

* 超时控制: `--wait-timeout=6m0s` 是一个经验值. 如果你的测试包含非常重的组件(如复杂的 GPU Operator 模拟), 可能需要增加到 10 分钟.

* 磁盘清理: 再次强调, 必须配合 `free-up-disk-space` 使用. Minikube 启动后会拉取大量 Docker 镜像, 如果不清理 Runner 预装的无用软件, 极易导致 `No space left on device` 错误.
