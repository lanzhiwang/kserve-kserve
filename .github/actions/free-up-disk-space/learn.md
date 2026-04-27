这个 `free-up-disk-space/action.yml` 是 GitHub Actions 玩家的"续命神器".

### 1. 为什么需要这个文件? (背景说明)

GitHub 托管的 Ubuntu Runner(运行器)默认磁盘空间非常紧张. 虽然总磁盘很大, 但预装了大量的开发工具(.NET, Android SDK, Haskell, CodeQL 等), 导致留给用户的可用空间通常只有 14GB ~ 18GB.

对于 KServe 这种项目:

* 构建多个大型 Docker 镜像(如 PyTorch/TensorFlow 运行时).

* 运行 KinD 或 Minikube(在 Runner 内部跑一个 K8s).

* 下载海量的 Go/Python 依赖.

默认空间极易爆满导致任务失败(Disk Full). 这个 Action 的核心作用就是通过"卸载预装软件"和"挂载大容量磁盘"来压榨出 30GB~50GB 的额外可用空间.

---

### 2. 为 `action.yml` 添加详细注释

```yaml
name: "Free-up disk space action"
# 清理 GitHub Runner 上不必要的工具和库, 并将 Docker 数据目录迁移至更大的 /mnt 磁盘
description: "Removes non-essential tools, libraries and cached files from GitHub action runner node and changes the docker data directory to /mnt/docker"

runs:
  using: "composite"
  steps:
    - name: Free up disk space
      shell: bash
      run: |
        # 清理前磁盘状态
        echo "Disk usage before cleanup:"
        df -hT

        # 删除非必需的开发环境和库, 这些通常占据了 10GB-20GB 空间
        # 这里的路径参考了 GitHub 官方镜像的维护说明
        # remove non-essential tools and libraries, see:
        # https://github.com/actions/runner-images/issues/2840#issuecomment-790492173
        # Haskell 编译器环境
        sudo rm -rf /opt/ghc
        # .NET Runtime & SDK
        sudo rm -rf /usr/share/dotnet
        # C++ Boost 库
        sudo rm -rf /usr/local/share/boost

        # 删除特定重型工具链:
        # Android SDK (约 12G), CodeQL 扫描工具 (约 5G), PowerShell (约 1.3G), Swift (约 1.7G)
        # delete libraries for Android (12G), CodeQL (5.3G), PowerShell (1.3G), Swift (1.7G)
        sudo rm -rf /usr/local/lib/android
        sudo rm -rf "${AGENT_TOOLSDIRECTORY}/CodeQL"
        sudo rm -rf /usr/local/share/powershell
        sudo rm -rf /usr/share/swift

        # 清理后磁盘状态
        echo "Disk usage after cleanup:"
        df -hT

    - name: Prune docker images
      shell: bash
      run: |
        # 清理 Docker 冗余数据
        echo "Pruning docker images"
        # 强制删除所有未使用的镜像、容器和网络, 释放宿主机 Docker 空间
        docker image prune -a -f
        docker system df
        df -hT

    - name: Move docker data directory
      shell: bash
      run: |
        # 这是一个高级技巧:
        # GitHub Runner 的根目录 / 空间有限, 但 /mnt 所在的虚拟磁盘通常有更大的未分配空间.

        # 停止 Docker 服务以进行目录迁移
        echo "Stopping docker service ..."
        sudo systemctl stop docker

        DOCKER_DEFAULT_ROOT_DIR=/var/lib/docker
        DOCKER_ROOT_DIR=/mnt/docker

        # 将 Docker 数据目录从 ${DOCKER_DEFAULT_ROOT_DIR} 物理移动到 ${DOCKER_ROOT_DIR}
        echo "Moving ${DOCKER_DEFAULT_ROOT_DIR} -> ${DOCKER_ROOT_DIR}"
        sudo mv ${DOCKER_DEFAULT_ROOT_DIR} ${DOCKER_ROOT_DIR}
        echo "Creating symlink ${DOCKER_DEFAULT_ROOT_DIR} -> ${DOCKER_ROOT_DIR}"
        # 创建软链接, 让系统依然认为 Docker 在原位置, 但实际存储在 /mnt
        sudo ln -s ${DOCKER_ROOT_DIR} ${DOCKER_DEFAULT_ROOT_DIR}
        # 验证软链接状态
        echo "$(sudo ls -l ${DOCKER_DEFAULT_ROOT_DIR})"

        # 重新加载配置并启动 Docker
        echo "Starting docker service ..."
        sudo systemctl daemon-reload
        sudo systemctl start docker
        echo "Docker service status:"

        # 检查 Docker 服务状态
        sudo systemctl --no-pager -l -o short status docker

```

---

### 3. 核心技术点解析

1. 暴力拆卸 (Rm -rf):

  GitHub Runner 预装了很多为了方便大多数开发者但对特定项目无用的东西. 脚本中删除的 `/usr/share/dotnet` 和 `/usr/local/lib/android` 是空间占用的"大头".

2. Docker 目录迁移 (The /mnt Trick):

  这是运维经验的体现. 在 Azure/AWS 提供的虚拟机中(GitHub Runner 运行在这些机器上), 根分区 `/` 往往较小, 但会挂载一个名为 `/mnt` 的临时磁盘(Ephemeral Storage). 通过 `mv` 加 `ln -s`(软链接), 可以让 Docker 使用这块更大的磁盘空间, 而不需要去修改复杂的 Docker Daemon 配置文件.

---

### 4. 使用场景

* E2E (End-to-End) 测试:

  当你需要在 Runner 上运行 `minikube start` 或 `kind create cluster` 时. K8s 集群本身加上拉取的系统镜像(kube-apiserver, etcd 等)会瞬间吞掉数 GB.

* 多阶段大型镜像构建:

  如果你在做 `docker build`, 且基础镜像(Base Image)非常大(比如包含 CUDA/cuDNN 的镜像), 在层构建过程中会产生大量中间层.

* Monorepo(单体大仓库)构建:

  如果一个 Repo 里有几十个组件需要同时编译, 生成的缓存文件(Go cache, Build artifacts)会迅速撑爆磁盘.

---

### 5. 使用方法

这个 Action 必须放在 Workflow 中所有正式构建步骤的最前面(通常在 `checkout` 之后立即执行), 否则等到磁盘满了再清理就晚了.

#### 示例代码 (`.github/workflows/e2e-test.yml`):

```yaml
name: E2E Test
on: [pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      # 关键步骤: 在所有重型操作前先腾空间
      - name: Free up disk space
        uses: ./.github/actions/free-up-disk-space

      # 之后再执行你的 K8s 部署或镜像构建
      - name: Set up Minikube
        uses: ./.github/actions/minikube-setup

      - name: Build Large Images
        run: make docker-build
```

### 总结

作为高级开发, 这个 Action 是处理 K8s 生态项目 CI 稳定性的"压舱石". 它不仅清理了空间, 还巧妙地利用了操作系统的挂载点(`/mnt`)来解决存储瓶颈. 如果没有它, KServe 这样复杂的项目很难在 GitHub 的免费运行器上跑完完整的 E2E 测试.
