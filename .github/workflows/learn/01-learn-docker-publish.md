```bash
$ tree -a .github/workflows
.github/workflows
├── agent-docker-publish.yml  ####################
├── artexplainer-docker-publish.yml  ####################
├── huggingface-cpu-docker-publish.yml  ####################
├── huggingface-docker-publish.yml  ####################
├── huggingface-vllm-docker-publish-manual.yml  ####################
├── kserve-controller-docker-publish.yml
├── kserve-llmisvc-controller-docker-publish.yml
├── kserve-localmodel-agent-docker-publish.yml
├── kserve-localmodel-controller-docker-publish.yml
├── lightgbm-docker-publish.yml
├── paddle-docker-publish.yml
├── pmml-docker-publish.yml
├── predictiveserver-docker-publish.yml
├── qpext-docker-publish.yml
├── router-docker-publish.yml
├── sklearnserver-docker-publish.yml
├── storage-initializer-docker-publisher.yml
├── tf2openapi-docker-publisher.yml
├── transformer-docker-publish.yml
├── xgbserver-docker-publisher.yml
├── custom-model-grpc-publish.yml
##########################################################################
├── automated-release.yml
├── comment-cherry-pick.yml
├── e2e-test-llmisvc.yaml
├── e2e-test.yml
├── go.yml
├── helm-publish.yml
├── pr-style-check.yml
├── precommit-check.yml
├── prepare-release.yml
├── prow-github.yml
├── prow-pr-automerge.yml
├── prow-pr-remove-lgtm.yml
├── python-publish.yml
├── python-test.yml
├── re-run-actions.yml
├── scheduled-go-security-scan.yml
├── scheduled-image-scan.yml
└── required-checks.yml

1 directory, 39 files
$
```

这个工作流文件 `huggingface-docker-publish.yml` 的核心任务是: 自动化构建、测试并发布 KServe 的 HuggingFace 模型服务器镜像.
由于 AI 镜像通常包含大量的依赖(如 PyTorch、Transformers 库), 该脚本在设计上特别注重了磁盘空间的管理和镜像标签的规范化.

---

### 1. 带有详细注释的工作流代码

```yaml
# 工作流名称: Huggingface 镜像发布器
name: Huggingface Docker Publisher

on:
  push:
    # 当代码推送到 master 分支时触发(通常发布为 latest 镜像)
    # Publish `master` as Docker `latest` image.
    branches:
      - master

    # 当推送以 'v' 开头的标签(如 v1.0.0)时触发(发布为正式版本镜像)
    # Publish `v1.2.3` tags as releases.
    tags:
      - v*

  # 针对任何 PR 触发测试
  # Run tests for any PRs.
  pull_request:
    # 路径过滤: 只有当以下文件变动时才运行, 避免无关变动浪费 CI 资源
    paths:
      # Python 源码变动
      - "python/**"
      # 排除 .github 目录(除非下面特殊指定)
      - "!.github/**"
      # 排除文档
      - "!docs/**"
      # 排除 Markdown 文件
      - "!**.md"
      # 本工作流自身变动
      - ".github/workflows/huggingface-docker-publish.yml"
      # 空间清理脚本变动
      - ".github/actions/free-up-disk-space/**"

env:
  IMAGE_NAME: huggingfaceserver

# 并发控制: 如果同一 PR 或分支有新提交, 取消正在进行的旧任务, 节省资源
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  # 任务一: 测试构建(验证 Dockerfile 是否正确)
  # Run tests.
  # See also https://docs.docker.com/docker-hub/builds/automated-testing/
  test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout source
        uses: actions/checkout@v4

      # 关键步骤: AI 镜像很大, 清理 Runner 磁盘以防构建过程中空间不足
      - name: Free-up disk space
        uses: ./.github/actions/free-up-disk-space

      # 设置 Docker Buildx(支持多平台构建和更强的缓存能力)
      - name: Setup Docker Buildx
        uses: docker/setup-buildx-action@v3
        with:
          cache-binary: true

      # 执行测试构建, push: false 表示仅验证构建过程, 不上传镜像
      - name: Run tests
        uses: docker/build-push-action@v5
        with:
          platforms: linux/amd64
          context: python
          file: python/huggingface_server.Dockerfile
          push: false
          # 禁用来源证明以解决特定构建插件的兼容性问题
          # https://github.com/docker/buildx/issues/1533
          provenance: false

  # 任务二: 正式推送镜像
  # Push image to GitHub Packages.
  # See also https://docs.docker.com/docker-hub/builds/
  push:
    # 只有测试任务通过后, 且是真正的 push 事件(不是 PR)时才执行
    # Ensure test job passes before pushing image.
    needs: test

    runs-on: ubuntu-latest
    # 只有测试任务通过后, 且是真正的 push 事件(不是 PR)时才执行
    if: github.event_name == 'push'

    steps:
      - name: Checkout source
        uses: actions/checkout@v4

      - name: Free-up disk space
        uses: ./.github/actions/free-up-disk-space

      - name: Setup Docker Buildx
        uses: docker/setup-buildx-action@v3
        with:
          cache-binary: true

      # 登录到 DockerHub, 账号密码存储在仓库的 Secrets 中
      - name: Login to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USER }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      # 动态计算镜像版本和 ID
      - name: Export version variable
        run: |
          IMAGE_ID=kserve/$IMAGE_NAME

          # 转换为全小写以符合 Docker 规范
          # Change all uppercase to lowercase
          IMAGE_ID=$(echo $IMAGE_ID | tr '[A-Z]' '[a-z]')

          # 从 git ref 中提取版本号 (如 refs/tags/v1.0.0 -> v1.0.0)
          # Strip git ref prefix from version
          VERSION=$(echo "${{ github.ref }}" | sed -e 's,.*/\(.*\),\1,')

          # Strip "v" prefix from tag name
          # [[ "${{ github.ref }}" == "refs/tags/"* ]] && VERSION=$(echo $VERSION | sed -e 's/^v//')

          # 如果分支是 master, 将版本标记为 latest
          # Use Docker `latest` tag convention
          [ "$VERSION" == "master" ] && VERSION=latest

          # 强制添加 -gpu 后缀, 表明该构建针对 GPU 环境(通常底层基于 CUDA)
          # Add "-gpu" suffix to the version
          VERSION="${VERSION}-gpu"

          # 将变量写入环境变量, 供后续步骤使用
          echo VERSION=$VERSION >> $GITHUB_ENV
          echo IMAGE_ID=$IMAGE_ID >> $GITHUB_ENV

      # 执行最终构建并推送到 DockerHub
      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          platforms: linux/amd64
          context: python
          file: python/huggingface_server.Dockerfile
          push: true
          tags: ${{ env.IMAGE_ID }}:${{ env.VERSION }}
          # https://github.com/docker/buildx/issues/1533
          provenance: false
          # 生成软件物料清单(Security/Compliance 审计用)
          sbom: true

```

---

### 2. 核心功能与含义说明

1. 路径过滤 (Path Filtering):

  这是一个典型的 Monorepo(单体仓库) 管理策略. 项目中可能有几十个镜像. 通过 `paths` 过滤, 确保只有修改了 `python/` 下的 Huggingface 相关代码时才触发构建, 避免了每次提交代码都重新构建几十个镜像的恐怖开销.

2. 两阶段任务 (Test-then-Push):

  * `test` 阶段: 在任何 PR 提交时运行, 确保你的修改没有破坏 Dockerfile 的构建逻辑.

  * `push` 阶段: 只有代码合并到 master 或发布 Tag 时才执行, 并真正修改 DockerHub 上的镜像.

3. 磁盘空间优化:

  `free-up-disk-space` 是这个项目的精髓. Huggingface 的镜像由于包含 PyTorch 往往超过 5GB, 构建时的临时层文件可能达到 20GB. 如果不清理 GitHub Runner 预装的无用软件(如 .NET, Android SDK), 构建会因磁盘满而崩溃.

4. 标签自动化 (Tagging Logic):

  脚本自动处理了 `master -> latest-gpu` 以及 `v1.2.3 -> v1.2.3-gpu` 的逻辑. 这意味着运维人员只需要管理 Git Tag, 镜像版本会保持同步.

---

### 3. 使用场景

* 开发者提交 PR: 当你修改了 `python/huggingface_server.py`, CI 会自动启动 `test` 任务, 反馈构建是否成功.

* 代码合并发布: 当你将功能合入 `master` 分支, CI 自动更新 `kserve/huggingfaceserver:latest-gpu` 镜像.

* 版本正式发布: 当你打下 `v0.15.0` 的标签, CI 会生成 `kserve/huggingfaceserver:v0.15.0-gpu`, 供生产环境固定版本使用.

---

### 4. 使用方法

1. 配置 Secrets:

  在 GitHub 仓库设置中(Settings -> Secrets and variables -> Actions), 必须添加以下两个密钥:

  * `DOCKER_USER`: 你的 DockerHub 用户名(如 `kserve`).

  * `DOCKER_PASSWORD`: 你的 DockerHub 访问令牌(PAT)或密码.

2. 触发构建:

  * 开发模式: 在本地修改 `python/` 目录下的代码并推送到 PR 分支.

  * 发布模式:
    ```bash
    git tag v0.1.0
    git push origin v0.1.0
    ```

3. 查看结果:

  在 GitHub 仓库的 `Actions` 选项卡中, 可以看到名为 `Huggingface Docker Publisher` 的运行记录.

### 运维专家建议:

该文件最后的 `sbom: true` 非常专业. 它生成了镜像的软件物料清单. 在企业级安全合规检查中, 这个功能可以帮助安全团队快速扫描镜像中包含的所有 Python 包及其版本, 从而识别已知漏洞(CVE).

---

这个 `huggingface-vllm-docker-publish-manual.yml` 文件是一个典型的手动发布流水线.
它与之前自动触发的流水线不同, 主要用于在特定时间点(如 vLLM 版本更新或需要补丁镜像时), 由运维人员手动触发, 同时构建并发布 CPU 和 GPU 两个版本的 HuggingFace 模型服务器镜像.

---

### 1. 带有详细注释的工作流代码

```yaml
# 工作流名称: 手动发布 Huggingface vLLM 镜像
name: Huggingface vLLM Docker Publisher

on:
  # 手动触发配置
  workflow_dispatch:
    inputs:
      # 手动执行时需要输入的参数: 版本号(例如 0.1.2)
      version:
        description: "Huggingface vLLM image version to publish"
        required: true

env:
  # 基础镜像名称变量
  IMAGE_NAME: huggingfaceserver

# 并发策略: 如果同一个分支重复触发, 取消正在进行的任务, 防止资源竞争和镜像覆盖
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  push:
    # 策略配置: 利用矩阵同时处理多个变体
    strategy:
      # 即使 CPU 版本构建失败, GPU 版本也要继续构建
      fail-fast: false
      matrix:
        image:
          # 定义 CPU 版本的参数
          - version: ${{ inputs.version }}
            path: "python/huggingface_server_cpu.Dockerfile"
          # 定义 GPU 版本的参数(版本号自动带上 -gpu 后缀)
          - version: ${{ inputs.version }}-gpu
            path: "python/huggingface_server.Dockerfile"

    runs-on: ubuntu-latest

    steps:
      - name: Checkout source
        uses: actions/checkout@v4

      # 调用本地自定义 Action: 清理磁盘空间
      # 深度学习镜像(尤其是包含 vLLM 和 CUDA 的)通常非常庞大(10GB+), 清理磁盘是必须的
      - name: Free-up disk space
        uses: ./.github/actions/free-up-disk-space

      # 初始化 Docker Buildx, 支持更高级的构建特性(如缓存、多平台等)
      - name: Setup Docker Buildx
        uses: docker/setup-buildx-action@v3
        with:
          cache-binary: true

      # 登录到 DockerHub 官方镜像仓库
      - name: Login to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USER }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      # 动态生成并规范化环境变量
      - name: Export image id and version variable
        run: |
          # 定义镜像全名 (例如 kserve/huggingfaceserver)
          IMAGE_ID=kserve/$IMAGE_NAME

          # 转换为全小写(Docker 规范要求)
          # Change all uppercase to lowercase
          IMAGE_ID=$(echo $IMAGE_ID | tr '[A-Z]' '[a-z]')

          # 强制版本号以 'v' 开头(例如输入 0.15.0 会变成 v0.15.0)
          # 这是为了保证发布产物的命名一致性
          # Add prefix v to version if it doesn't start with v
          if [[ ${{ matrix.image.version }} != v* ]]; then
            VERSION="v${{ matrix.image.version }}"
          else
            VERSION="${{ matrix.image.version }}"
          fi

          # 写入环境变量以便后续步骤引用
          echo IMAGE_ID=$IMAGE_ID >> $GITHUB_ENV
          echo VERSION=$VERSION >> $GITHUB_ENV

      # 执行真正的构建与推送操作
      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          platforms: linux/amd64
          context: python
          # 根据矩阵参数动态选择 Dockerfile (CPU 或 GPU)
          file: ${{ matrix.image.path }}
          push: true
          # 最终镜像标签格式为 IMAGE_ID:VERSION
          tags: ${{ env.IMAGE_ID }}:${{ env.VERSION }}
          # 禁用 provenance 记录以解决某些注册表兼容性问题
          # https://github.com/docker/buildx/issues/1533
          provenance: false
          # 生成 SBOM (软件物料清单), 增强供应链安全性
          sbom: true

```

---

### 2. 核心含义深度解析

1. `workflow_dispatch` (手动挡):

  这是该文件的核心. 它不在代码 push 时运行, 而是给运维人员提供了一个 UI 按钮. 这在 AI 领域很常见, 因为模型服务器的镜像(特别是集成了 vLLM 的)体积巨大且构建极慢, 通常不希望每次小代码改动都触发完整构建, 而是在准备好发布 Release Candidate 时手动触发.

2. `strategy.matrix` (矩阵并行):

  这里定义了一个包含两个对象的矩阵. GitHub 会自动派生出两个独立的任务:

    * 任务 A: 使用 `huggingface_server_cpu.Dockerfile`, 版本号为 `v(input)`.

    * 任务 B: 使用 `huggingface_server.Dockerfile`, 版本号为 `v(input)-gpu`.

    这保证了同一个版本号下的 CPU 和 GPU 镜像具有高度的逻辑一致性.

3. 版本号修整 (Normalization):

  脚本中使用了 `if [[ ${{ matrix.image.version }} != v* ]]`. 这是为了解决"人的因素": 无论操作员输入的是 `0.15.0` 还是 `v0.15.0`, 最终产出的镜像标签都会整齐划一地变成 `v0.15.0`.

4. 磁盘空间管理 (`free-up-disk-space`):

  vLLM 镜像通常包含大量的深度学习库(PyTorch, vLLM, CUDA 等). 在构建过程中, Docker 的中间层会消耗巨大空间. 如果不调用这个清理 Action, 构建任务极大概率会报错 `No space left on device`.

---

### 3. 使用场景

作为高级运维/开发, 你会在以下场景使用此文件:

* 特定组件发布: 当 KServe 的核心逻辑没变, 但 vLLM 库发布了安全补丁或性能优化时, 你需要带版本号重新发布 HuggingFace 推理镜像.

* 手动补跑/修复: 如果之前的自动化构建由于网络原因失败, 或者你需要针对特定的 Git Commit 发布一个临时的调试镜像.

* Release 发布流程: 在项目正式发布新版本前, 由 Release Manager 手动触发, 生成稳定版本的 CPU/GPU 镜像.

---

### 4. 使用方法

由于这是 `workflow_dispatch` 触发, 你需要按照以下步骤操作:

1. 打开 GitHub 仓库页面.

2. 点击 Actions 选项卡.

3. 在左侧列表中找到 "Huggingface vLLM Docker Publisher".

4. 点击右侧显示的 "Run workflow" 下拉按钮.

5. 在 "Huggingface vLLM image version to publish" 输入框中输入版本号(例如 `0.15.0`).

6. 点击 "Run workflow" 绿色按钮.

检查结果:

* 在 Actions 运行详情中, 你会看到两个并行的 Job: 一个是 CPU 版本, 一个是 GPU 版本.

* 构建完成后, 你可以到 DockerHub 的 `kserve/huggingfaceserver` 仓库下看到新增的两个标签: `v0.15.0` 和 `v0.15.0-gpu`.

### 运维专家提示:

这个脚本中的 `sbom: true` 选项非常关键. 对于 vLLM 这种复杂的依赖栈, 生成的 SBOM(软件物料清单)可以帮助你快速确认镜像中到底包含的是哪个版本的 `transformers`、`torch` 或 `vllm` 库, 这在生产环境排查 Bug 时非常有价值.
