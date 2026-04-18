# Quickstart Guide

Welcome to the KServe Quickstart Guide! This guide will help you set up a KServe Quickstart environment for testing and experimentation.
欢迎阅读 KServe 快速入门指南! 本指南将帮助您设置 KServe 快速入门环境, 用于测试和实验.

By the end of this guide, you will have a fully functional KServe environment ready for experimentation.
看完本指南, 您将拥有一个功能齐全的 KServe 环境, 可以进行实验了.

> warning
> KServe Quickstart Environments are for experimentation use only. For production installation, see our [Administrator's Guide](https://kserve.github.io/website/docs/admin-guide/overview).
> KServe 快速入门环境仅供实验用途. 如需在生产环境中安装, 请参阅我们的管理员指南.
>

## Prerequisites

Before you can get started with a KServe Quickstart deployment, you will need to ensure you have the following prerequisites installed:
在开始 KServe 快速入门部署之前, 您需要确保已安装以下必备组件:

### Tools

Make sure you have the following tools installed:
请确保您已安装以下工具:

- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) - The Kubernetes command-line tool
- [helm](https://helm.sh/docs/intro/install/) - for installing KServe and other Kubernetes operators
- [git](https://git-scm.com/downloads) - for cloning the KServe repository

> Verify Installations
> Run the following commands to verify that you have the required tools installed:
> To verify `kubectl` installation, run:
> ```
> kubectl version --client
> ```
> To verify `helm` installation, run:
> ```
> helm version
> ```
> To verify `git` installation, run:
> ```
> git --version
> ```
>

### Kubernetes Cluster

> Version Requirements
> Kubernetes version **1.32 or higher** is required.
>

You will need a running Kubernetes cluster with properly configured kubeconfig to run KServe. You can use any Kubernetes cluster, but for local development and testing, we recommend using `kind` (Kubernetes in Docker) or `minikube`.
运行 KServe 需要一个已正确配置 kubeconfig 的 Kubernetes 集群. 您可以使用任何 Kubernetes 集群, 但对于本地开发和测试, 我们建议使用 `kind` (Docker 中的 Kubernetes) 或 `minikube`.

- Local Cluster (Kind/Minikube)

**Using Kind (Kubernetes in Docker)**:

If you want to run a local Kubernetes cluster, you can use [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/). It allows you to create a Kubernetes cluster using Docker container nodes.
如果你想运行本地 Kubernetes 集群, 可以使用 [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/). 它允许你使用 Docker 容器节点创建 Kubernetes 集群.

First, ensure you have [Docker installed](https://docs.docker.com/engine/install/) on your machine. Install Kind by following the [Kind Quick Start Guide](https://kind.sigs.k8s.io/docs/user/quick-start/) if you haven't done so already.
首先, 请确保您的计算机上已[安装 Docker](https://docs.docker.com/engine/install/). 如果您尚未安装 Kind, 请按照 [Kind 快速入门指南](https://kind.sigs.k8s.io/docs/user/quick-start/)进行安装.

Then, you can create a local Kubernetes cluster with the following command:
然后, 您可以使用以下命令创建本地 Kubernetes 集群:

```bash
kind create cluster
```

**Using Minikube**:

If you prefer to use Minikube, you can follow the [Minikube Quickstart Guide](https://minikube.sigs.k8s.io/docs/start/) to set up a local Kubernetes cluster.
如果您更喜欢使用 Minikube, 您可以按照 [Minikube 快速入门指南](https://minikube.sigs.k8s.io/docs/start/)设置本地 Kubernetes 集群.

First, ensure you have [Minikube installed](https://minikube.sigs.k8s.io/docs/start/) on your machine. Then, you can start a local Kubernetes cluster with the following command:
首先, 请确保您的机器上已[安装 Minikube](https://minikube.sigs.k8s.io/docs/start/). 然后, 您可以使用以下命令启动本地 Kubernetes 集群:

```bash
minikube start
```

- Existing Kubernetes Cluster

If you have access to an existing Kubernetes cluster, you can use that as well. Ensure that your kubeconfig is properly configured to connect to the cluster. You can verify your current context with:
如果您可以访问现有的 Kubernetes 集群, 也可以使用它. 请确保您的 kubeconfig 文件已正确配置以连接到该集群. 您可以使用以下命令验证当前上下文:

```bash
kubectl config current-context
```

Verify your cluster meets the version requirements by running:
运行以下命令验证您的集群是否满足版本要求:

```bash
kubectl version --output=json
```

The server version in the output should show version 1.32 or higher:
输出中的服务器版本应显示为 1.32 或更高版本:

```json
{
  "serverVersion": {
    "major": "1",
    "minor": "32",
    ...
  }
}
```

## Install KServe Quickstart Environment
安装 KServe 快速入门环境

Once you have the prerequisites installed and a Kubernetes cluster running, you can proceed with the KServe Quickstart installation.
安装好必备组件并运行 Kubernetes 集群后, 即可开始进行 KServe 快速入门安装.

First, clone the KServe repository:

```bash
git clone https://github.com/kserve/kserve.gitcd kserve
```

Then choose your installation scenario:
然后选择您的安装方案:

- KServe Only

- KServe + LocalModel

- LLMIsvc Only

- KServe + LLMIsvc + LocalModel

- Dependencies Only

> More Installation Options
> 更多安装选项
> For detailed installation instructions, customization options, and troubleshooting:
> 有关详细安装说明、自定义选项和故障排除:
> - [KServe Installation Guide KServe](https://kserve.github.io/website/docs/install/kserve-install)
> - [LLMInferenceService Installation Guide LLM](https://kserve.github.io/website/docs/install/llmisvc-install)
> - [LocalModel Installation Guide ](https://kserve.github.io/website/docs/install/localmodel-install)
>

## Next Steps

Now that you have a KServe Quickstart environment set up, you can start deploying and testing machine learning models:
现在您已经设置好了 KServe 快速入门环境, 可以开始部署和测试机器学习模型了:

- 📖 **[First GenAI InferenceService](https://kserve.github.io/website/docs/getting-started/genai-first-isvc)** - Deploy your first GenAI model using InferenceService
- 📖 **[First Predictive InferenceService](https://kserve.github.io/website/docs/getting-started/predictive-first-isvc)** - Deploy your first predictive model using InferenceService
