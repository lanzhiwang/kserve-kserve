在 KServe 这样的大型云原生项目中, 由于组件极多(如前面的目录所示), 构建过程非常耗时.
为了提高效率, 通常会采用"一次构建, 多次测试"的策略. 这个 `base-download/action.yml` 就是该策略的核心组件.

---

### 1. 为 `action.yml` 添加详细注释

这是一个 Composite Action(复合动作), 它允许你将多个步骤封装在一起, 像使用单个插件一样在工作流中调用.

```yaml
# Action 的名称, 显示在 GitHub Actions 的执行日志中
name: "Base Download Actions"
# 对该 Action 功能的简要描述
description: "A wrapper around download docker artifact to download a set of base images"

runs:
  # 声明这是一个复合 Action, 允许组合使用其他 Action 和 shell 命令
  using: "composite"
  steps:
    # 第一步: 从 GitHub 存储库的 Artifacts(产物库)中下载之前上传的文件
    - name: Download base artifacts
      uses: actions/download-artifact@v4
      with:
        # 指定下载到的本地临时目录
        path: ./tmp
        # 使用通配符匹配 Artifact 名称.
        # 这里依赖于环境变量 BASE_ARTIFACT_PREFIX, 例如值为 "kserve-images"
        # 那么它会匹配所有如 "kserve-images-controller", "kserve-images-agent" 的产物
        pattern: ${{ env.BASE_ARTIFACT_PREFIX }}-*
        # 如果匹配到多个 Artifact, 将它们的内容全部合并到 path 指定的同一个目录中
        # 避免为每个产物创建一个子文件夹, 方便后续统一处理
        merge-multiple: true

    # 第二步: 调用项目内部的另一个本地 Action, 将下载好的镜像文件加载到 Docker 中
    - name: Load base images
      # 引用同目录下 actions/load-docker-images 文件夹中的 action.yaml
      uses: ./.github/actions/load-docker-images
      with:
        # 告诉加载脚本去刚才下载到的 ./tmp 目录寻找镜像包(通常是 .tar 文件)
        directory: ./tmp
```

---

### 2. 核心含义详解

该文件的核心逻辑是 "产物分发与环境恢复":

1. `actions/download-artifact@v4`:

  * 它不是从 Docker Hub 下载, 而是从 GitHub Actions 内部的存储空间下载.

  * `pattern` 结合 `merge-multiple` 是为了批量处理. 假设你的构建任务输出了 5 个不同的组件镜像, 你不需要写 5 次下载, 通过一个前缀就能全部拉取.

2.  本地 Action 嵌套 (`uses: ./.github/actions/load-docker-images`):

  * 这体现了高级 CI/CD 的模块化设计. 下载后的产物只是文件(通常是 `docker save` 出来的 `.tar` 包), 需要执行 `docker load` 才能变成可用的镜像. 这个加载逻辑被封装在另一个 Action 里, 实现了关注点分离.

---

### 3. 使用场景(Why we need this?)

在复杂的 K8s 项目中, 这个 Action 通常用于 E2E (端到端) 测试阶段:

* 场景描述:

  一个工作流(Workflow)包含两个阶段:

  1. Build 阶段: 构建所有的基础镜像(如 Controller, Router, Agent), 并使用 `actions/upload-artifact` 将它们上传, 命名为 `kserve-base-controller` 等.

  2. Test 阶段 (Parallel): 启动多个并行的测试 Job(例如分别在不同版本的 K8s 上测试).

* 痛点: 如果每个测试 Job 都去重新 build 镜像, 会浪费大量时间且浪费 GitHub 的计算资源.

* 解决方案: 测试 Job 调用这个 `base-download` Action, 直接把 Build 阶段生成的镜像"捡"回来加载到本地环境(如 Minikube 或 Kind 中).

---

### 4. 使用方法(How to use?)

要在工作流中使用这个 Action, 你需要确保两点:

1. 前置条件: 在之前的 Job 中已经上传了对应的 Artifact.

2. 变量注入: 必须定义 `BASE_ARTIFACT_PREFIX` 环境变量.

#### 示例代码 (`.github/workflows/e2e-test.yml`):

```yaml
jobs:
  # 假设这是之前的构建任务
  build-base:
    runs-on: ubuntu-latest
    steps:
      - name: Build and Upload
        # ... 构建逻辑 ...
        # 最终上传名为 "my-project-images-controller" 的产物

  # 现在的测试任务
  e2e-test:
    needs: build-base
    runs-on: ubuntu-latest
    env:
      # 必须设置这个变量, 供 base-download Action 使用
      BASE_ARTIFACT_PREFIX: my-project-images
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      # 调用我们解析的这个 Action
      - name: Prepare Base Images
        uses: ./.github/actions/base-download

      # 此时镜像已加载, 可以运行测试
      - name: Run Tests
        run: kubectl apply -f ...

```

### 总结

作为高级开发, 你会发现这种设计大大降低了 Workflow 的维护成本. 如果未来下载逻辑变了(比如从 v4 升级到 v5, 或者存放路径变了), 你只需要修改这一处 `action.yml`, 而项目中几十个以 `docker-publish` 或 `e2e-test` 为主的 Workflow 都会自动生效.
