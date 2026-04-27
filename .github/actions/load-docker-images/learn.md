这个 `load-docker-images/action.yaml` 是云原生 CI/CD 流水线中的"激活器".
它的作用是将通过 `docker save` 命令打包生成的离线镜像文件(`.tar`)重新加载到当前运行环境(Runner)的 Docker 引擎中.

在 KServe 这种复杂的项目中, 这通常是 "构建(Build)" 与 "测试(Test)" 阶段之间的桥梁.

---

### 1. 为 `action.yaml` 添加详细注释

这是一个 Composite Action. 它通过封装循环逻辑, 简化了在不同工作流中加载多个镜像的操作.

```yaml
# Action 的显示名称
name: "Load docker images"
# 详细描述: 从指定目录加载 tar 镜像文件并随后清理该目录
description: "Loads docker images from the tar files in specified director and deletes the directory"

# 定义输入参数
inputs:
  directory:
    description: "Path to the directory which contains the tar files"
    required: true # 必须提供包含 tar 文件的路径

runs:
  # 声明使用复合模式, 允许将多个步骤或脚本封装在一起
  using: composite
  steps:
    - name: Load docker images
      # 在复合 Action 中, 每个 run 步骤必须明确指定 shell 种类
      shell: bash
      run: |
        # 1. 使用 find 命令查找指定目录下第一层级的所有文件
        # -maxdepth 1: 只看当前目录, 不递归子目录
        # -type f: 只查找文件
        files=$(find ${{ inputs.directory }} -maxdepth 1 -type f)

        # 2. 遍历找到的所有文件
        for file in ${files[@]};do
          # 打印当前正在处理的文件名, 方便在 GitHub Actions 日志中排查
          echo "Loading image $(basename ${file})"

          # 3. 执行核心命令: 将 tar 包加载回 Docker 镜像库
          # -i (input): 指定输入文件
          docker image load -i ${file}
        done

        # 4. 环境清理: 加载完成后删除临时目录及其中的 tar 文件
        # 这样做是为了释放 GitHub Runner 极其宝贵的磁盘空间(通常只有 14GB 左右)
        rm -rf ${{ inputs.directory }}

        # 5. 验证环节: 列出当前系统中的所有镜像, 确保加载成功并留存日志证据
        docker image ls

```

---

### 2. 核心逻辑深度解析

1. 自动化批量处理:

  该 Action 并不需要你手动指定每个镜像的文件名. 它利用 `find` 命令动态获取目录下所有的文件并循环处理. 这意味着如果你有 10 个组件镜像, 只需一次调用.

2. 本地缓存激活:

  在 GitHub Actions 中, Job 之间是隔离的. 如果你在 Job A 中 `docker build` 了镜像并 `upload-artifact` 提交了, 那么 Job B 在执行时, 本地 Docker 引擎是空的. 这个 Action 配合 `download-artifact` 实现了"在 Job B 中恢复 Job A 的镜像环境".

3. 磁盘空间优化:

  镜像 `.tar` 文件通常很大(几百 MB 到 GB 级别). `rm -rf` 这一行非常关键, 防止因为存储了多份重复的镜像包导致 Runner 磁盘撑爆(Disk Full), 这是高级运维人员必须考虑的鲁棒性设计.

---

### 3. 使用场景

在 KServe 项目的开发流水线中, 主要用于以下场景:

* E2E (End-to-End) 集成测试:

  在 `build` 阶段, 你会并行构建 `controller`、`agent`、`router` 等镜像. 构建完成后把它们存为 Artifacts. 在后续的 `e2e-test` 阶段, 你需要把这些镜像加载到 Runner 环境, 然后推送到本地的 `minikube` 或 `Kind` 集群中进行真实测试.

* 跨架构构建验证:

  例如在 x86 机器上构建 ARM 镜像并导出, 然后在另一台机器上加载验证.

* 避免重复拉取:

  如果某些基础镜像下载非常慢, 可以先将其打包为 Artifact, 在后续 Job 中直接 Load, 比从外部 Registry 拉取更快.

---

### 4. 使用方法

这个 Action 通常紧跟在 `actions/download-artifact` 之后使用.

#### 示例代码 (用于 `.github/workflows/e2e-test.yml`):

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      # 第一步: 下载之前 Build 好的镜像压缩包
      - name: Download Artifacts
        uses: actions/download-artifact@v4
        with:
          name: kserve-images
          path: ./my-images # 将产物下载到这个目录

      # 第二步: 调用本 Action 加载镜像
      - name: Load Images into Docker
        uses: ./.github/actions/load-docker-images
        with:
          directory: ./my-images # 必须与上面的 path 对应

      # 第三步: 现在镜像已经在本地 Docker 里了, 可以执行测试或推送
      - name: Verify and Run
        run: |
          docker ps
          # 比如将加载好的镜像推送到本地集群
          kind load docker-image kserve-controller:latest

```

### 运维专家建议:

* 文件名建议: 在 `docker save` 时, 建议文件名以 `.tar` 结尾, 虽然脚本没强制检查后缀, 但规范命名能减少 Bug.

* 引用路径: 注意 `uses: ./.github/actions/load-docker-images` 路径必须准确, 这是相对于代码仓库根目录的相对路径.

* Shell 声明: 如果你在编写自己的 Composite Action, 记住一定要像代码中那样写 `shell: bash`, 否则 GitHub 会报错.
