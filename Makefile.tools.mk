# 这份 Makefile 的核心哲学是 "构建环境自包含" (Self-contained Build Environment).
# 它不依赖于开发者系统全局安装的工具, 而是自动在项目本地下载、版本化并管理所有依赖.

# ==============================================================================
# 路径与环境定义
# ==============================================================================

# 定义本地二进制文件存放目录, 默认为项目根目录下的 bin 目录
LOCALBIN ?= $(shell pwd)/bin

# 这是一个典型的"目录创建"目标. 如果 bin 目录不存在则创建它.
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

# Python 虚拟环境配置: 将 venv 放在 bin 目录下隐藏, 保持根目录整洁
PYTHON_VENV = $(LOCALBIN)/.venv
PYTHON_BIN = $(PYTHON_VENV)/bin


# ==============================================================================
# 工具二进制路径定义 (逻辑名称 -> 物理路径)
# ==============================================================================
# 这样做的好处是: 在后续代码中引用工具时, 如果路径或安装方式变了, 只需改这里.

## Tool binary names.
GOLANGCI_LINT = $(LOCALBIN)/golangci-lint
CONTROLLER_GEN = $(LOCALBIN)/controller-gen
ENVTEST = $(LOCALBIN)/setup-envtest
YQ = $(LOCALBIN)/yq
HELM_DOCS = $(LOCALBIN)/helm-docs

# Python 工具路径
BLACK_FMT = $(PYTHON_BIN)/black
UV = $(PYTHON_BIN)/uv
RUFF = $(PYTHON_BIN)/ruff

# ==============================================================================
# Go 工具安装逻辑 (基于 Go Module)
# ==============================================================================

## Tool versions are defined in kserve-deps.env (included in main Makefile)

# golangci-lint: 代码静态检查工具
.PHONY: golangci-lint
golangci-lint: $(GOLANGCI_LINT)
$(GOLANGCI_LINT): $(LOCALBIN)
	$(call go-install-tool,$(GOLANGCI_LINT),github.com/golangci/golangci-lint/v2/cmd/golangci-lint,$(GOLANGCI_LINT_VERSION))
# $ make -n --dry-run golangci-lint
# echo "==> [DEBUG] Macro go-install-tool called with:"
# echo "    Arg 1 (Target Path): /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/golangci-lint"
# echo "    Arg 2 (Package URL): github.com/golangci/golangci-lint/v2/cmd/golangci-lint"
# echo "    Arg 3 (Version):     v2.9.0"
# [ -f "/Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/golangci-lint-v2.9.0" ] || {
# 	set -e;
# 	package=github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.9.0 ;
# 	echo "Downloading ${package}" ;
# 	rm -f /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/golangci-lint || true ;
# 	GOBIN=/Users/huzhi/work/code/go_code/ai/kserve/kserve/bin go install ${package} ;
# 	go mod tidy ;
# 	mv /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/golangci-lint /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/golangci-lint-v2.9.0 ;
# } ;
# ln -sf /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/golangci-lint-v2.9.0 /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/golangci-lint
# $

# controller-gen: K8s Operator 开发中用于生成 CRD 和 Deepcopy 代码
## Download controller-gen locally if necessary.
.PHONY: controller-gen
controller-gen: $(CONTROLLER_GEN)
$(CONTROLLER_GEN): $(LOCALBIN)
	$(call go-install-tool,$(CONTROLLER_GEN),sigs.k8s.io/controller-tools/cmd/controller-gen,$(CONTROLLER_TOOLS_VERSION))
# $ make -n --dry-run controller-gen
# echo "==> [DEBUG] Macro go-install-tool called with:"
# echo "    Arg 1 (Target Path): /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/controller-gen"
# echo "    Arg 2 (Package URL): sigs.k8s.io/controller-tools/cmd/controller-gen"
# echo "    Arg 3 (Version):     v0.19.0"
# [ -f "/Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/controller-gen-v0.19.0" ] || {
# 	set -e;
# 	package=sigs.k8s.io/controller-tools/cmd/controller-gen@v0.19.0 ;
# 	echo "Downloading ${package}" ;
# 	rm -f /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/controller-gen || true ;
# 	GOBIN=/Users/huzhi/work/code/go_code/ai/kserve/kserve/bin go install ${package} ;
# 	go mod tidy ;
# 	mv /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/controller-gen /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/controller-gen-v0.19.0 ;
# } ;
# ln -sf /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/controller-gen-v0.19.0 /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/controller-gen
# $

# envtest: 用于运行 K8s 控制器单元测试的本地 API Server 环境
## Download envtest-setup locally if necessary.
.PHONY: envtest
envtest: $(ENVTEST)
$(ENVTEST): $(LOCALBIN)
	$(call go-install-tool,$(ENVTEST),sigs.k8s.io/controller-runtime/tools/setup-envtest,$(ENVTEST_VERSION))
# $ make -n --dry-run envtest
# echo "==> [DEBUG] Macro go-install-tool called with:"
# echo "    Arg 1 (Target Path): /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/setup-envtest"
# echo "    Arg 2 (Package URL): sigs.k8s.io/controller-runtime/tools/setup-envtest"
# echo "    Arg 3 (Version):     latest"
# [ -f "/Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/setup-envtest-latest" ] || {
# 	set -e; package=sigs.k8s.io/controller-runtime/tools/setup-envtest@latest ;
# 	echo "Downloading ${package}" ;
# 	rm -f /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/setup-envtest || true ;
# 	GOBIN=/Users/huzhi/work/code/go_code/ai/kserve/kserve/bin go install ${package} ;
# 	go mod tidy ;
# 	mv /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/setup-envtest /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/setup-envtest-latest ;
# } ;
# ln -sf /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/setup-envtest-latest /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/setup-envtest
# $

# ==============================================================================
# 非 Go 工具安装逻辑 (Shell 脚本与链接处理)
# ==============================================================================

## Download yq locally if necessary.
.PHONY: yq
yq: $(YQ)
$(YQ): $(LOCALBIN)
	@[ -f "$(YQ)-$(YQ_VERSION)" ] || { \
	BIN_DIR=$(LOCALBIN) hack/setup/cli/install-yq.sh && \
	mv $(LOCALBIN)/yq $(YQ)-$(YQ_VERSION) ; \
	} ; \
	ln -sf "$$(basename $(YQ)-$(YQ_VERSION))" "$(YQ)"
# $ make -n --dry-run yq
# [ -f "/Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/yq-v4.52.1" ] || {
# 	BIN_DIR=/Users/huzhi/work/code/go_code/ai/kserve/kserve/bin hack/setup/cli/install-yq.sh &&
# 	mv /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/yq /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/yq-v4.52.1 ;
# } ;
# ln -sf "$(basename /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/yq-v4.52.1)" "/Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/yq"
# $

## Download helm-docs locally if necessary.
.PHONY: helm-docs
helm-docs: $(HELM_DOCS)
$(HELM_DOCS): $(LOCALBIN)
	$(call go-install-tool,$(HELM_DOCS),github.com/norwoodj/helm-docs/cmd/helm-docs,$(HELM_DOCS_VERSION))
# $ make -n --dry-run helm-docs
# echo "==> [DEBUG] Macro go-install-tool called with:"
# echo "    Arg 1 (Target Path): /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/helm-docs"
# echo "    Arg 2 (Package URL): github.com/norwoodj/helm-docs/cmd/helm-docs"
# echo "    Arg 3 (Version):     v1.12.0"
# [ -f "/Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/helm-docs-v1.12.0" ] || {
# 	set -e; package=github.com/norwoodj/helm-docs/cmd/helm-docs@v1.12.0 ;
# 	echo "Downloading ${package}" ;
# 	rm -f /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/helm-docs || true ;
# 	GOBIN=/Users/huzhi/work/code/go_code/ai/kserve/kserve/bin go install ${package} ;
# 	go mod tidy ;
# 	mv /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/helm-docs /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/helm-docs-v1.12.0 ;
# } ;
# ln -sf /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/helm-docs-v1.12.0 /Users/huzhi/work/code/go_code/ai/kserve/kserve/bin/helm-docs
# $

# ==============================================================================
# Python 环境与工具 (Venv 隔离)
# ==============================================================================

# 使用 | (Order-only prerequisite) 确保 bin 目录存在, 但不因为 bin 的时间戳改变而触发重构
$(PYTHON_VENV): | $(LOCALBIN)
	python3 -m venv $(PYTHON_VENV)
	$(PYTHON_BIN)/pip install --upgrade pip

# 安装特定版本的 Python 格式化和 Lint 工具
$(BLACK_FMT): $(PYTHON_VENV)
	$(PYTHON_BIN)/pip install black==$(BLACK_FMT_VERSION)

$(UV): $(PYTHON_VENV)
	$(PYTHON_BIN)/pip install uv==$(UV_VERSION)

$(RUFF): $(PYTHON_VENV)
	$(PYTHON_BIN)/pip install ruff==$(RUFF_VERSION)

# ==============================================================================
# 核心宏定义: go-install-tool
# ==============================================================================
# 这是本 Makefile 的精华. 它解决了"如何管理本地多版本 Go 工具"的问题.
# $1 - 二进制完整路径 (如 .../bin/yq)
# $2 - Package 路径 (如 github.com/...)
# $3 - 版本号 (如 v1.50.0)

# go-install-tool will 'go install' any package with custom target and name of binary, if it doesn't exist
# $1 - target path with name of binary
# $2 - package url which can be installed
# $3 - specific version of package
define go-install-tool
@echo "==> [DEBUG] Macro go-install-tool called with:"
@echo "    Arg 1 (Target Path): $(1)"
@echo "    Arg 2 (Package URL): $(2)"
@echo "    Arg 3 (Version):     $(3)"
@[ -f "$(1)-$(3)" ] || { \
set -e; \
package=$(2)@$(3) ;\
echo "Downloading $${package}" ;\
rm -f $(1) || true ;\
GOBIN=$(LOCALBIN) go install $${package} ;\
go mod tidy ;\
mv $(1) $(1)-$(3) ;\
} ;\
ln -sf $(1)-$(3) $(1)
endef

# 为什么要这么写?(设计哲学)
#
# A. 消除"在我的机器上能运行"的问题 (Reproducibility)
# 传统的 Makefile 可能会直接写 go install github.com/.... 这会导致:
# 开发者 A 安装了 v1.1, 开发者 B 安装了 v1.2, 两人生成的代码不一致.
# CI 机器上没有该工具, 导致构建失败.
# 此写法通过硬编码版本号并在本地隔离安装, 确保了所有环境(开发、测试、生产、CI)使用的工具链完全一致.
#
# B. 软链接与版本缓存策略
# go-install-tool 宏采用了一种聪明的做法:
# 实际文件名为 golangci-lint-v1.50.0.
# 逻辑入口为软链接 golangci-lint.
# 原因: 如果你升级了版本号, Makefile 会检测到 golangci-lint-v1.51.0 不存在, 从而触发下载, 并更新软链接. 旧版本依然保留在硬盘上, 方便回滚或缓存, 且不会污染系统的 PATH.
#
# C. Python Venv 的自动化管理
# 通常 Python 开发者需要手动 source .venv/bin/activate.
# 此写法: 直接定义 PYTHON_BIN = $(PYTHON_VENV)/bin, 然后通过 $(PYTHON_BIN)/pip 调用. 这意味着开发者不需要手动激活环境, 只需执行 make black, Makefile 会自动创建环境、安装依赖并运行.
#
# D. 使用 Order-only Prerequisites (|)
# 在 $(PYTHON_VENV): | $(LOCALBIN) 中, | 符号非常专业. 它意味着:
# 如果 bin 目录不存在, 先创建它.
# 但是, 即使 bin 目录下的其他文件发生了变化(导致 bin 目录的修改时间更新), 也不会重新触发 Python 环境的创建. 这避免了不必要的重复构建.
#
# 使用场景
# 云原生/Kubernetes Operator 开发: 这是 Kserve、Controller-runtime 等项目的标准写法. 管理 controller-gen 和 envtest 的版本极其重要, 因为不同版本生成的 YAML 可能不兼容.
# CI/CD 流水线: 在 GitHub Actions 或 GitLab CI 中, 你只需要一行 make golangci-lint. 脚本会自动准备好环境. 由于工具都在 bin/ 下, 你可以很容易地设置缓存该目录, 加速后续构建.
# 多语言混合项目: 当一个项目同时包含 Go 后端和 Python 辅助脚本/模型处理时, 这种方式统一了两种语言的依赖管理体验.
# 受限权限环境: 开发者在公司电脑上可能没有 sudo 权限去全局安装工具. 这种将工具安装在项目目录下的做法不需要任何系统权限.
