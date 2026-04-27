```bash
$ tree -a .github/workflows
.github/workflows
├── agent-docker-publish.yml
├── artexplainer-docker-publish.yml
├── huggingface-cpu-docker-publish.yml
├── huggingface-docker-publish.yml.  ####################
├── huggingface-vllm-docker-publish-manual.yml
├── kserve-controller-docker-publish.yml
├── kserve-llmisvc-controller-docker-publish.yml
├── kserve-localmodel-agent-docker-publish.yml
├── kserve-localmodel-controller-docker-publish.yml
├── learn-docker-publish.md
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

1 directory, 40 files
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
