```bash
$ tree -a .github/workflows
.github/workflows
├── agent-docker-publish.yml
├── artexplainer-docker-publish.yml
├── huggingface-cpu-docker-publish.yml
├── huggingface-docker-publish.yml  ####################
├── huggingface-vllm-docker-publish-manual.yml
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
├── go.yml  ####################
├── python-test.yml  ####################
├── e2e-test.yml
├── e2e-test-llmisvc.yaml
├── pr-style-check.yml
├── precommit-check.yml
##########################################################################
├── automated-release.yml
├── comment-cherry-pick.yml
├── helm-publish.yml
├── prepare-release.yml
├── prow-github.yml
├── prow-pr-automerge.yml
├── prow-pr-remove-lgtm.yml
├── python-publish.yml
├── re-run-actions.yml
├── scheduled-go-security-scan.yml
├── scheduled-image-scan.yml
└── required-checks.yml

1 directory, 39 files
$
```

这个 `go.yml` 文件不仅仅是运行 `go test`, 它实现了一个完整的代码覆盖率质量门禁(Quality Gate). 它能够自动计算当前分支的覆盖率, 并与 `master` 分支的基准数据进行对比, 最后将对比结果以评论的形式反馈在 Pull Request (PR) 中.

---

### 1. 带有详细注释的工作流代码

```yaml
name: Go Test

on:
  push:
    # 当代码推送到 master 或 release 开头的分支时触发
    branches: [master, release*]
    # 忽略仅 Markdown 文件的变动, 节省 CI 资源
    paths-ignore:
      - "**.md"

  pull_request:
    # PR 触发路径过滤:
    # 包含所有路径, 但排除 python、docs 和 md 文件.
    # 特别包含本 workflow 文件, 确保修改 CI 逻辑时能触发测试.
    paths:
      - "**"
      - "!python/**"
      - "!.github/**"
      - "!docs/**"
      - "!**.md"
      - ".github/workflows/go.yml"

  # 允许手动触发执行
  workflow_dispatch:

# 并发控制: 如果同一分支有新的提交, 取消正在进行的旧任务
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

# 权限设置: 允许工作流写入内容和 PR 评论(用于发布覆盖率报告)
permissions:
  contents: write
  pull-requests: write

jobs:
  # 第一个 Job: 执行测试并生成原始覆盖率数据
  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - name: Check out code into the Go module directory
        uses: actions/checkout@v4

      # 安装 Go 环境, 版本从项目根目录的 go.mod 文件中自动读取
      - name: Set up Go 1.x
        uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
        id: go

      # 下载项目所有依赖, 包含测试依赖
      - name: Get dependencies
        run: |
          go get -v -t -d ./...

      - name: Test
        id: test
        run: |
          # 设置必要的环境变量
          export GOPATH=/home/runner/go
          export PATH=$PATH:/usr/local/kubebuilder/bin:/home/runner/go/bin

          # 下载 yq 工具, 用于后续可能的 YAML 处理(虽然脚本内未显式使用, 但在构建环境常见)
          wget -O $GOPATH/bin/yq https://github.com/mikefarah/yq/releases/download/v4.28.1/yq_linux_amd64
          chmod +x $GOPATH/bin/yq

          # 执行 Makefile 中定义的测试指令, 通常会包含 go test -coverprofile=coverage.out
          make test

          # 执行覆盖率处理脚本
          ./coverage.sh

          # 提取总覆盖率百分比并设为 step 的输出变量
          echo ::set-output name=coverage::$(./coverage.sh | tr -s '\t' | cut -d$'\t' -f 3)

      - name: Print coverage
        run: |
          echo "Coverage output is ${{ steps.test.outputs.coverage }}"

      # 将生成的覆盖率结果文件上传为 Artifact, 供下一个 Job 使用
      - name: upload cover profile artifact
        uses: actions/upload-artifact@v4
        with:
          name: coverage.out
          path: coverage.out
          if-no-files-found: error

  # 第二个 Job: 检查覆盖率变化并发布报告
  check-coverage:
    # 依赖 test 任务成功完成
    needs: test
    runs-on: ubuntu-latest
    name: Check Coverage
    steps:
      - name: checkout
        uses: actions/checkout@v4

      # 下载上一个 Job 产生的覆盖率文件
      - name: Download cover profile artifact
        id: download-coverage
        uses: actions/download-artifact@v4
        with:
          name: coverage.out

      # 计算当前分支的总覆盖率数值
      - name: Extract coverage percentage
        id: current-coverage
        run: |
          if [ -f coverage.out ]; then
            COVERAGE=$(go tool cover -func=coverage.out | grep total: | awk '{print $3}' | sed 's/%//')
            echo "coverage=$COVERAGE" >> $GITHUB_OUTPUT
          else
            echo "coverage=0" >> $GITHUB_OUTPUT
          fi

      # 关键步骤: 使用第三方 Action 下载 master 分支上最近一次成功的基准覆盖率数据
      - name: download artifact (master.breakdown)
        id: download-master-breakdown
        uses: dawidd6/action-download-artifact@v9
        with:
          branch: master
          workflow_conclusion: success
          name: master.breakdown
          if_no_artifact_found: warn

      - name: download artifact (master-coverage.out)
        id: download-master-coverage
        uses: dawidd6/action-download-artifact@v9
        with:
          branch: master
          workflow_conclusion: success
          name: master-coverage.out
          if_no_artifact_found: warn

      # 解析 master 分支的基准覆盖率数值
      - name: Extract master coverage percentage
        id: master-coverage
        run: |
          if [ -f master-coverage.out ]; then
            MASTER_COVERAGE=$(go tool cover -func=master-coverage.out | grep total: | awk '{print $3}' | sed 's/%//')
            echo "coverage=$MASTER_COVERAGE" >> $GITHUB_OUTPUT
          else
            echo "coverage=0" >> $GITHUB_OUTPUT
          fi

      # 生成完整的函数级覆盖率明细报告
      - name: Generate full coverage breakdown
        id: full_coverage_report
        run: |
          if [ -f coverage.out ]; then
            REPORT_CONTENT=$(go tool cover -func=coverage.out) # This command outputs function-level coverage [5]
            echo "report<<EOF" >> $GITHUB_OUTPUT # Start HERE-doc for multi-line output [3]
            echo "$REPORT_CONTENT" >> $GITHUB_OUTPUT
            echo "EOF" >> $GITHUB_OUTPUT # End HERE-doc
          else
            echo "report=No coverage report found." >> $GITHUB_OUTPUT
          fi

      # 使用专用的 Go 覆盖率检查工具进行比对
      - name: check test coverage
        id: coverage
        uses: vladopajic/go-test-coverage@v2
        continue-on-error: true
        with:
          config: ./.github/.testcoverage.yml
          # 如果是 master 分支, 则更新基准文件
          breakdown-file-name: ${{ github.ref_name == 'master' && 'master.breakdown' || '' }}
          diff-base-breakdown-file-name: ${{ steps.download-master-breakdown.outputs.found_artifact == 'true' && 'master.breakdown' || '' }}

      # 如果当前是 master 分支, 上传新的基准文件供后续 PR 比对使用
      - name: upload artifact (master.breakdown)
        uses: actions/upload-artifact@v4
        if: github.ref_name == 'master'
        with:
          name: master.breakdown
          path: master.breakdown
          if-no-files-found: error

      # 打印调试信息
      - name: Previous coverage
        run: |
          echo "Previous Coverage ${{ steps.master-coverage.outputs.coverage }}"

      - name: Current coverage
        run: |
          echo "Current Coverage ${{ steps.current-coverage.outputs.coverage }}"

      # 在 PR 下面自动发布对比报告
      - name: post coverage report
        # 仅在 PR 场景下运行, 发布覆盖率上升/下降的视觉反馈
        # this has evalated permission to post back the coverage, only restricted to this step.
        if: github.event_name == 'pull_request_target'
        uses: thollander/actions-comment-pull-request@v3
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          comment-tag: coverage-report
          pr-number: ${{ github.event.pull_request.number }}
          message: |
            ## 📊 Go Test Coverage Report

            ${{ steps.current-coverage.outputs.coverage > steps.master-coverage.outputs.coverage && '✅ **Overall code coverage increased.**' || steps.current-coverage.outputs.coverage < steps.master-coverage.outputs.coverage && '❌ **Overall code coverage decreased.**' || 'ℹ️ **Overall code coverage unchanged.**' }}

            **🔍 Coverage Summary**
            - **Pull Request Coverage:** `${{ steps.current-coverage.outputs.coverage }}%`
            - **Main Branch Coverage:** `${{ steps.master-coverage.outputs.coverage }}%`

            <details>
            <summary>📄 Click to expand full coverage breakdown</summary>

            ```
            ${{ steps.full_coverage_report.outputs.report }}
            ```

            </details>

      # 如果是 master 分支, 持久化存储当前的 coverage.out 供下一次 PR 比对
      - name: Rename and upload master coverage
        if: github.ref_name == 'master'
        run: mv coverage.out master-coverage.out

      - name: Upload master coverage artifact
        if: github.ref_name == 'master'
        uses: actions/upload-artifact@v4
        with:
          name: master-coverage.out
          path: master-coverage.out
          if-no-files-found: error

```

---

### 2. 该文件的核心含义

1. 分阶段测试 (Parallel Jobs):

  工作流分为两个任务: `test` 负责构建和运行测试, `check-coverage` 负责分析和报告. 这种解耦方式使得"测试逻辑"和"报告逻辑"互不干扰, 且可以利用 GitHub 的 Artifact 系统跨 Job 传递数据.

2. 基准比对 (Baseline Comparison):

  这是该 CI 最强大的地方. 它通过 `dawidd6/action-download-artifact` 跨工作流下载 `master` 分支生成的旧 Artifact. 这样, 开发者在提交 PR 时就能立即知道: "我的修改是否让项目的测试覆盖率降低了?"

3. 开发者反馈循环 (Feedback Loop):

  通过 `thollander/actions-comment-pull-request`, CI 会在 PR 页面直接评论. 开发者不需要去 Action 日志里翻找, 一眼就能看到覆盖率报表.

---

### 3. 使用场景

* Pull Request 审查:

  当一个新功能提交时, 如果评论显示 `Overall code coverage decreased`(覆盖率下降), Maintainer 可以要求开发者补全单元测试后再合并.

* Master 分支健康监控:

  每当有代码合入 master, CI 都会更新基准数据(`master-coverage.out`), 确保基准数据始终是最新的.

* 代码合规性门禁:

  配合 `.github/.testcoverage.yml` 的配置(如 `vladopajic/go-test-coverage` 插件), 可以设置强制门禁: 如果覆盖率低于某个百分比或下降超过一定比例, 直接让 CI 变红, 阻止合并.

---

### 4. 使用方法

对于项目开发者来说, 使用方法非常简单:

1. 正常提交代码: 修改 Go 代码并推送到自己的分支.

2. 创建 PR: 发起指向 `master` 分支的 Pull Request.

3. 等待反馈:

  * CI 会自动开始运行 `Go Test`.

  * 几分钟后, PR 页面会出现一条由 `github-actions` 发布的评论, 展示覆盖率对比图.

4. 调试覆盖率:

  * 点击评论中的 `Click to expand full coverage breakdown` 展开折叠内容.

  * 查看输出, 确认哪些新增的函数或逻辑行没有被测试覆盖到.

### 运维专家建议:

在大型 Go 项目中, `go get ./...` 可能会因为网络问题变慢. 建议在 `setup-go` 步骤中开启缓存功能(`cache: true`), 可以显著加快后续任务的依赖下载速度.

---

这个 `python-test.yml` 是一个高度优化、支持多版本并行测试、且具有深度存储管理逻辑的工业级流水线. 它负责 KServe 项目中所有 Python 核心库及各种模型服务器(Sklearn, XGBoost, HuggingFace 等)的单元测试和代码覆盖率统计.

---

### 1. 带有详细注释的工作流代码

```yaml
# 工作流名称: Python 包测试与验证
name: Python package

on:
  push:
    # 触发条件 1: 代码推送到 master 或 release 分支
    branches: [master, release*]
    paths-ignore:
      # 忽略文档修改
      - "**.md"

  # 触发条件 2: Pull Request 变动
  pull_request:
    # 路径过滤: 仅当 Python 代码、工作流脚本或磁盘清理脚本变动时触发
    paths:
      - "python/**"
      - "!.github/**"
      - "!docs/**"
      - "!**.md"
      - ".github/workflows/python-test.yml"
      - ".github/actions/free-up-disk-space/**"

  # 触发条件 3: 允许手动触发
  workflow_dispatch:

# 并发控制: 如果同一 PR 有新提交, 自动取消旧的正在运行的任务, 节省 GitHub 算力
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest

    # 策略配置: 实现跨 Python 版本的兼容性测试矩阵
    strategy:
      # 即使 3.10 失败, 3.11 和 3.12 也要继续跑完
      fail-fast: false
      matrix:
        python-version: ["3.10", "3.11", "3.12"]

    steps:
      - name: Checkout source
        uses: actions/checkout@v4

      # 关键步骤: KServe 依赖包(如 PyTorch, Paddle)体积巨大, 必须清理磁盘预装软件腾出空间
      - name: Free-up disk space
        uses: ./.github/actions/free-up-disk-space

      - name: Set up Python ${{ matrix.python-version }}
        id: setup-python
        # 注: 此处通常应为 actions/setup-python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      # 使用现代化的 Python 包管理器 uv, 比传统 pip 快 10-100 倍
      - name: Install uv
        run: pip install uv

      - name: Set up virtualenv
        run: |
          uv venv .venv
          # source .venv/bin/activate
          # pip install --upgrade pip

      # 缓存机制: 利用 GitHub Cache 存储虚拟环境, 极大缩短后续流水线执行时间
      - name: Load uv cache
        uses: actions/cache@v4
        id: cached-uv
        with:
          path: .venv
          key: uv-${{ runner.os }}-${{ hashFiles('**/uv.lock') }}

      - name: Verify and fix root venv if needed
        run: |
          if [ ! -e .venv/bin/python3 ]; then
            echo "Cached venv is broken, recreating..."
            rm -rf .venv
            uv venv .venv
          fi

      # -----------------------------------------------------------------------------------------
      # 以下是针对各个子模块的独立测试逻辑(采用相同的模式: 加载缓存 -> 安装 -> 执行 pytest)
      # -----------------------------------------------------------------------------------------

      # ----------------------------------------Kserve Unit Tests
      # load cached kserve venv if cache exists
      - name: Load cached kserve venv
        id: cached-kserve-dependencies
        uses: actions/cache@v4
        with:
          path: python/kserve/.venv
          key: kserve-venv-${{ steps.setup-python.outputs.python-version }}-${{ hashFiles('**/kserve/uv.lock') }}

      # install kserve dependencies if cache does not exist
      - name: Install kserve dependencies
        if: steps.cached-kserve-dependencies.outputs.cache-hit != 'true'
        run: |
          cd python/kserve
          make install_dependencies

      - name: Install kserve
        run: |
          cd python/kserve
          make dev_install

      - name: Test kserve
        run: |
          cd python
          source kserve/.venv/bin/activate
          pytest --cov=kserve ./kserve

      - name: Test kserve Storage
        run: |
          cd python
          source kserve/.venv/bin/activate
          pytest --cov=storage ./storage

      # 2. Numpy 1.x 兼容性回归测试(非常专业的设计, 确保旧版库兼容性)
      # ----------------------------------------Kserve Numpy 1.x Unit Tests
      - name: Setup kserve numpy 1-x directory
        run: |
          mkdir -p python/kserve-numpy-1-x
          cp -r python/kserve/* python/kserve-numpy-1-x
          cd python/kserve-numpy-1-x
          # update the lock file without installing dependencies
          uv pip install "numpy<2.0"

      - name: Load cached kserve numpy 1-x venv
        id: cached-kserve-numpy-1-x-dependencies
        uses: actions/cache@v3
        with:
          path: python/kserve-numpy-1-x/.venv
          key: kserve-numpy-1-x-venv-${{ steps.setup-python.outputs.python-version }}-${{ hashFiles('**/kserve-numpy-1-x/uv.lock') }}

      # install kserve numpy 1-x dependencies if cache does not exist
      - name: Install kserve numpy 1-x dependencies
        if: ${{ steps.cached-kserve-numpy-1-x-dependencies.outputs.cache-hit != 'true' }}
        run: |
          cd python/kserve-numpy-1-x
          make install_dependencies

      - name: Install kserve numpy 1-x
        run: |
          cd python/kserve-numpy-1-x
          make dev_install

      - name: View numpy version
        run: |
          cd python/kserve-numpy-1-x
          uv pip show numpy

      - name: Test kserve numpy 1-x
        run: |
          cd python
          source kserve-numpy-1-x/.venv/bin/activate
          pytest --cov=kserve ./kserve-numpy-1-x

      # ----------------------------------------Sklearn Server Unit Tests
      # load cached sklearn venv if cache exists
      - name: Load cached sklearn venv
        id: cached-sklearn-dependencies
        uses: actions/cache@v4
        with:
          path: python/sklearnserver/.venv
          key: sklearn-venv-${{ steps.setup-python.outputs.python-version }}-${{ hashFiles('**/kserve/uv.lock', '**/sklearnserver/uv.lock') }}

        # install sklearn server dependencies if cache does not exist
      - name: Install sklearn dependencies
        if: steps.cached-sklearn-dependencies.outputs.cache-hit != 'true'
        run: |
          cd python/sklearnserver
          make install_dependencies

      - name: Install sklearnserver
        run: |
          cd python/sklearnserver
          make dev_install

      - name: Test sklearnserver
        run: |
          cd python
          source sklearnserver/.venv/bin/activate
          pytest --cov=sklearnserver ./sklearnserver

      # ----------------------------------------Xgb Server Unit Tests
      # load cached xgb venv if cache exists
      - name: Load cached xgb venv
        id: cached-xgb-dependencies
        uses: actions/cache@v4
        with:
          path: python/xgbserver/.venv
          key: xgb-venv-${{ steps.setup-python.outputs.python-version }}-${{ hashFiles('**/kserve/uv.lock', '**/xgbserver/uv.lock') }}

        # install xgb server dependencies if cache does not exist
      - name: Install xgb dependencies
        if: steps.cached-xgb-dependencies.outputs.cache-hit != 'true'
        run: |
          cd python/xgbserver
          make install_dependencies

      - name: Install xgbserver
        run: |
          cd python/xgbserver
          make dev_install

      - name: Test xgbserver
        run: |
          cd python
          source xgbserver/.venv/bin/activate
          pytest --cov=xgbserver ./xgbserver

      # ----------------------------------------Pmml Server Unit Tests
      # load cached pmml venv if cache exists
      - name: Load cached pmml venv
        id: cached-pmml-dependencies
        uses: actions/cache@v4
        with:
          path: python/pmmlserver/.venv
          key: pmml-venv-${{ steps.setup-python.outputs.python-version }}-${{ hashFiles('**/kserve/uv.lock', '**/pmmlserver/uv.lock') }}

        # install pmml server dependencies if cache does not exist
      - name: Install pmml dependencies
        if: steps.cached-pmml-dependencies.outputs.cache-hit != 'true'
        run: |
          cd python/pmmlserver
          make install_dependencies

      - name: Install pmmlserver
        run: |
          cd python/pmmlserver
          make dev_install

      - name: Test pmmlserver
        run: |
          cd python
          source pmmlserver/.venv/bin/activate
          pytest --cov=pmmlserver ./pmmlserver

      # ----------------------------------------Lgb Server Unit Tests
      # load cached lgb venv if cache exists
      - name: Load cached lgb venv
        id: cached-lgb-dependencies
        uses: actions/cache@v4
        with:
          path: python/lgbserver/.venv
          key: lgb-venv-${{ steps.setup-python.outputs.python-version }}-${{ hashFiles('**/kserve/uv.lock', '**/lgbserver/uv.lock') }}

        # install lgb server dependencies if cache does not exist
      - name: Install lgb dependencies
        if: steps.cached-lgb-dependencies.outputs.cache-hit != 'true'
        run: |
          cd python/lgbserver
          make install_dependencies

      - name: Install lgbserver
        run: |
          cd python/lgbserver
          make dev_install

      - name: Test lgbserver
        run: |
          cd python
          source lgbserver/.venv/bin/activate
          pytest --cov=lgbserver ./lgbserver

      # ----------------------------------------Paddle Server Unit Tests
      # load cached paddle venv if cache exists
      - name: Load cached paddle venv
        id: cached-paddle-dependencies
        uses: actions/cache@v4
        with:
          path: python/paddleserver/.venv
          key: paddle-venv-${{ steps.setup-python.outputs.python-version }}-${{ hashFiles('**/kserve/uv.lock', '**/paddleserver/uv.lock') }}

      - name: Install paddle dependencies
        if: steps.cached-paddle-dependencies.outputs.cache-hit != 'true'
        run: |
          echo "python version ${{ steps.setup-python.outputs.python-version }}"
          cd python/paddleserver
          make install_dependencies

      - name: Install paddleserver
        run: |
          cd python/paddleserver
          make dev_install

      - name: Test paddleserver
        run: |
          cd python
          source paddleserver/.venv/bin/activate
          pytest --cov=paddleserver ./paddleserver

      # Huggingface CPU Server 测试(最重型的测试项)
      # ----------------------------------------Huggingface CPU Server Unit Tests
      # load cached huggingface cpu venv if cache exists
      - name: Load cached huggingface cpu venv
        id: huggingface-cpu-dependencies
        uses: actions/cache@v4
        with:
          # 使用 /mnt 目录是因为这里磁盘空间更大(通过之前的 free-up-disk-space 挂载)
          path: /mnt/python/huggingfaceserver-cpu-venv
          key: huggingface-cpu-venv-${{ steps.setup-python.outputs.python-version }}-${{ hashFiles('**/kserve/uv.lock', '**/huggingfaceserver/uv.lock') }}

      - name: Setup Python environment
        run: |
          sudo mkdir -p /mnt/python/huggingfaceserver-cpu-venv
          sudo chown -R $USER /mnt/python/huggingfaceserver-cpu-venv
          uv venv /mnt/python/huggingfaceserver-cpu-venv
          echo "/mnt/python/huggingfaceserver-cpu-venv/bin" >> $GITHUB_PATH

      - name: Install build dependencies for vLLM
        run: |
          # vLLM 等高性能库需要编译, 安装必要的编译工具链
          sudo apt-get update -y
          sudo apt-get install -y gcc-12 g++-12 libnuma-dev python3-dev
          sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 10 --slave /usr/bin/g++ g++ /usr/bin/g++-12

      - name: Install huggingface cpu server
        run: |
          export VIRTUAL_ENV=/mnt/python/huggingfaceserver-cpu-venv
          cd python/huggingfaceserver
          make install_cpu_dependencies

      - name: Run tests
        run: |
          cd python/huggingfaceserver
          /mnt/python/huggingfaceserver-cpu-venv/bin/python -m ensurepip --upgrade
          /mnt/python/huggingfaceserver-cpu-venv/bin/python -m pip install --upgrade pip

          /mnt/python/huggingfaceserver-cpu-venv/bin/python -m pip install pytest pytest-cov
          bash tests/setup_vllm.sh
          source /mnt/python/huggingfaceserver-cpu-venv/bin/activate
          # 排除 vllm 相关测试, 因为在没有 GPU 的 GitHub Runner 上无法完全运行 vllm 逻辑
          /mnt/python/huggingfaceserver-cpu-venv/bin/python -m pytest --cov=huggingfaceserver -vv -k 'not test_vllm'
          # TODO: The following tests need to be reworked since IPEX support is relatively new for both vLLM and KServe
          # poetry run -- pytest --cov=huggingfaceserver -vv tests/test_vllm_chat_with_reasoning.py
          # poetry run -- pytest --cov=huggingfaceserver -vv tests/test_vllm_chat_with_tools.py
          # poetry run -- pytest --cov=huggingfaceserver -vv tests/test_vllm_generative.py
        env:
          VLLM_ENGINE_ITERATION_TIMEOUT_S: 3600

      - name: Free space after cpu tests
        run: |
          df -hT

```

---

### 2. 核心含义深度解析

1. 极速包管理器 `uv` 的深度应用:

  该流水线彻底抛弃了 `pip`, 转而使用 Rust 编写的 `uv`. 在 AI 项目中, 依赖项极其庞大, `uv` 的并行下载和硬链接特性可以节省数分钟的等待时间.

2. 精细化的缓存策略 (Multi-layer Caching):

  流水线没有对整个 `python/` 目录进行笼统缓存, 而是针对 `kserve`、`sklearnserver`、`paddleserver` 等每个子模块分别维护 `uv.lock` 对应的缓存. 这种做法保证了: 如果你只改了 Sklearn 部分的代码, Kserve 核心库和 Huggingface 的缓存依然有效, 不需要重新安装.

3. 针对 AI 场景的磁盘空间管理:

  * 清理: 调用 `free-up-disk-space` 删除 Android SDK 等无用软件.

  * 外挂空间: 将最庞大的 `huggingfaceserver` 环境放在 `/mnt` 分区, 利用 GitHub Runner 宿主机上更大的临时磁盘空间.

4. 兼容性保障 (Numpy 1.x):

  AI 领域最近正在从 Numpy 1.x 迁移到 2.x. 脚本中专门克隆了一份代码并在 `numpy < 2.0` 环境下跑一遍, 这是典型的高级回归测试逻辑, 防止新功能破坏了对旧版基础库的支持.

---

### 3. 使用场景

* PR 质量门禁: 当贡献者修改了任何一个模型服务器的代码, 该流水线会确保所有的子服务器依然能正常工作, 且在 Python 3.10~3.12 之间没有兼容性问题.

* 依赖冲突检测: 由于使用了 `uv.lock` 进行哈希校验, 一旦有人修改了 `pyproject.toml` 导致依赖冲突, CI 会在安装阶段立即报错.

* 代码覆盖率监控: 每个测试步骤都带有 `--cov`, 结果可以汇总并对接第三方服务(如 Codecov), 确保新增代码经过了充分测试.

---

### 4. 使用方法

1. 自动执行:

  * 开发者只需在 `python/` 目录下提交代码并推送到分支, GitHub 会自动启动这个 Matrix 任务.

2. 手动调试/补跑:

  * 如果某个 Python 版本的测试因网络波动失败, 可以在 GitHub Actions 页面点击 "Re-run failed jobs".

  * 可以通过 "Run workflow" 手动选择分支运行.

3. 本地模拟建议:

  * 由于脚本使用了 `make install_dependencies` 和 `uv`, 开发者在本地也应该使用 `uv` 并在相应的子目录下运行相同的命令, 以确保本地环境与 CI 环境一致.

### 运维专家提示:

注意 `huggingface-cpu` 任务中的 `vLLM` 构建步骤. 由于 GitHub Runner 是 CPU 环境, 虽然安装了 `gcc-12`, 但该任务通过 `-k 'not test_vllm'` 避开了需要显卡驱动的测试逻辑. 这是在受限的 CI 环境中测试重型 AI 框架的典型折中方案.

---


这个文件是 KServe 的端到端(End-to-End)测试大脑. 由于 KServe 涉及大量的组件(Controller、Agent、各种模型运行时、网络层等), 这个流水线采用了"先全量构建, 后并发测试"的工业级设计架构.

---

### 1. 为 `e2e-test.yml` 添加详细注释

```yaml

```

---

### 2. 该文件的核心含义

这个流水线的设计体现了 "分治法" 和 "生产者-消费者" 模型:

1. 生产者(Build Jobs):

  * 通过 `docker build` 将代码转化为镜像.

  * 通过 `docker save` 转化为磁盘文件.

  * 通过 `upload-artifact` 暂存到 GitHub 服务器.

  * 优点: 镜像只构建一次, 避免 10 几个测试 Job 重复构建.

2. 消费者(Test Jobs):

  * 每个 Job 负责一个特定的功能域(如 `test-llm` 只测大模型).

  * 使用 `matrix` 策略(Helm vs Kustomize)确保安装包的质量.

  * 通过 `download-artifact` 和 `load-docker-images` 快速恢复运行环境.

3.  环境模拟:

  * 大量使用 `minikube-setup` 在 Runner 中拉起 K8s 环境.

  * 针对特定功能(如 `test-modelcache`)甚至拉起了 3 节点的虚拟集群.

---

### 3. 使用场景

* 开发者提交代码: PR 触发后, CI 会全量运行测试, 确保没有破坏现有功能(Regression Testing).

* 版本发布验证: 在 `release-*` 分支上运行, 确保交付给用户的 Helm Chart 和 Kustomize 配置是百分之百可用的.

* 兼容性检查: 例如 `test-raw` 任务中, 同时测试了 `istio-ingress` 和 `gatewayapi` 两种网络层实现.

---

### 4. 使用方法与排查技巧

#### 如何运行?

* 自动: 向 `master` 分支提交 PR 即可.

* 手动: 在 GitHub Actions 页面选择 `E2E Tests` 工作流, 点击 `Run workflow`.

#### 如何排查失败?

1. 定位阶段: 先看是 `Build` 挂了(代码编译/Dockerfile 问题)还是 `Test` 挂了(功能逻辑问题).

2. 查看状态检查日志: 每个 Job 末尾都有 `Check system status` 步骤. 如果测试失败, 点开这里可以看到 `kubectl get pods`、`kubectl describe` 的输出, 通常能直接看到 Pod Crash 的原因.

3. Artifact 下载: 如果无法复现问题, 可以去 Action 的产物列表下载对应的镜像 tar 包, 在本地执行 `docker load` 还原 CI 现场.

#### 高级提示:

该文件中的 `compression-level: 0` 和 `free-up-disk-space` 是 senior 运维的标志性操作. K8s 镜像动辄数 GB, 不清理磁盘会导致 Runner 爆掉; 不关闭压缩会导致上传产物花费 20 分钟以上, 关闭后仅需 1 分钟.

这个流水线是 Kserve 项目能够保持高稳定性、快速迭代的核心基石. 如果你在维护类似项目, 这个结构非常值得参考!
