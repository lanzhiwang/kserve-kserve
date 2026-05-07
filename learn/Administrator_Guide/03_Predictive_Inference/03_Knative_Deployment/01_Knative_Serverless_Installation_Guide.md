# Knative mode Installation Guide

* https://kserve.github.io/website/docs/0.16/admin-guide/serverless

KServe's Knative serverless deployment mode leverages Knative to provide autoscaling based on request volume and supports scale down to and from zero. It also supports revision management and canary rollout based on revisions.
KServe 的 Knative 无服务器部署模式利用 Knative 提供基于请求量的自动扩缩容功能, 并支持缩减至零和从零开始扩缩容. 它还支持版本管理和基于版本号的金丝雀发布.

This mode is particularly useful for:
此模式尤其适用于:

- Cost optimization by automatically scaling resources based on demand
  通过根据需求自动扩展资源来优化成本

- Environments with varying or unpredictable traffic patterns
  交通模式变化多端或难以预测的环境

- Burst traffic scenarios where rapid scaling is required
  需要快速扩展的突发流量场景

- Scenarios where resources should be freed when not in use
  资源在不使用时应释放的场景

- Managing multiple model revisions and canary deployments
  管理多个模型版本和金丝雀部署

## Applicability for Predictive Inference
预测推理的适用性

Knative deployment is particularly well-suited for predictive inference workloads because:
原生部署尤其适用于预测推理工作负载, 因为:

- Predictive inference typically has shorter response times that work well with Knative's concurrency model
  预测推理通常响应时间更短, 与 Knative 的并发模型非常契合.

- CPU-based models can efficiently scale to zero when not in use
  基于 CPU 的模型在不使用时可以高效地缩减到零.

- Knative's request-based scaling aligns with the traffic patterns of many predictive workloads
  Knative 基于请求的扩展方式与许多预测性工作负载的流量模式相符.

- Canary deployments and revisions enable safe updates to predictive models
  金丝雀部署和修订能够安全地更新预测模型

> info
> Knative serverless Deployment is recommended primarily for predictive inference workloads.
> 原生无服务器部署主要推荐用于预测推理工作负载.
>

For generative inference workloads that typically require GPU resources and have longer processing times, the [Standard Kubernetes Deployment](https://kserve.github.io/website/docs/0.16/admin-guide/kubernetes-deployment) approach is recommended.
对于通常需要 GPU 资源且处理时间较长的生成推理工作负载, 建议[采用标准 Kubernetes 部署](https://kserve.github.io/website/docs/0.16/admin-guide/kubernetes-deployment)方法.

Kubernetes 1.32 is the minimally required version and please check the following recommended Knative, Istio versions for the corresponding Kubernetes version.
Kubernetes 1.32 是最低要求版本, 请查看以下推荐的 Knative 和 Istio 版本, 以了解其与 Kubernetes 版本对应的要求.

## Recommended Version Matrix

| Kubernetes Version | Recommended Istio Version | Recommended Knative Version |
| ------------------ | ------------------------- | --------------------------- |
| 1.32               | 1.27,1.28                 | 1.19,1.20                   |
| 1.33               | 1.27,1.28                 | 1.19,1.20                   |
| 1.34               | 1.28                      | 1.19,1.20                   |

## 1. Install Knative Serving
安装 Knative Serving

Please refer to [Knative Serving install guide](https://knative.dev/docs/admin/install/serving/install-serving-with-yaml/).
请参考 [Knative Serving 安装指南](https://knative.dev/docs/admin/install/serving/install-serving-with-yaml/).

> tip
> If you are looking to use PodSpec fields such as nodeSelector, affinity or tolerations which are now supported in the v1beta1 API spec, you need to turn on the corresponding [feature flags](https://knative.dev/docs/admin/serving/feature-flags) in your Knative configuration.
> 如果您希望使用 PodSpec 字段(例如 nodeSelector、affinity 或 tolerations, 这些字段现在在 v1beta1 API 规范中不受支持), 则需要在 Knative 配置中启用相应的[功能标志](https://knative.dev/docs/admin/serving/feature-flags).
>

> warning
> Knative 1.13.1 requires Istio 1.20+, gRPC routing does not work with previous Istio releases, see [release notes](https://github.com/knative/serving/releases/tag/knative-v1.13.1).
> Knative 1.13.1 需要 Istio 1.20+, gRPC 路由与之前的 Istio 版本不兼容, 请[参阅发行说明](https://github.com/knative/serving/releases/tag/knative-v1.13.1).
>

## 2. Install Networking Layer
安装网络层

The recommended networking layer for KServe is [Istio](https://istio.io/) as currently it works best with KServe, please refer to the [Istio install guide](https://knative.dev/docs/admin/install/installing-istio). Alternatively you can also choose other networking layers like [Kourier](https://github.com/knative-sandbox/net-kourier) or [Contour](https://projectcontour.io/), see [how to install Kourier with KServe guide](https://kserve.github.io/website/docs/0.16/admin-guide/serverless/kourier-networking).
目前推荐的 KServe 网络层是 [Istio](https://istio.io/), 因为它与 KServe 的兼容性最佳, 请参阅 [Istio 安装指南](https://knative.dev/docs/admin/install/installing-istio). 您也可以选择其他网络层, 例如 [Kourier](https://github.com/knative-sandbox/net-kourier) 或 [Contour](https://projectcontour.io/), 请[参阅 Kourier 与 KServe 的集成指南](https://kserve.github.io/website/docs/0.16/admin-guide/serverless/kourier-networking).

## 3. Install Cert Manager
安装证书管理器

The minimally required Cert Manager version is 1.15.0 and you can refer to [Cert Manager](https://cert-manager.io/docs/installation/).
证书管理器的最低版本要求为 1.15.0, 您可以参考[证书管理器](https://cert-manager.io/docs/installation/).

> note
> Cert manager is required to provision webhook certs for production grade installation, alternatively you can run self signed certs generation script.
> 生产级安装需要使用证书管理器来配置 webhook 证书, 或者您可以运行自签名证书生成脚本.
>

## 4. Install KServe
安装 KServe

### Install using Helm
使用 Helm 安装

Install KServe CRDs
安装 KServe CRD

```bash
helm install kserve-crd oci://ghcr.io/kserve/charts/kserve-crd --version v0.16.0
```

Install KServe Resources
安装 KServe 资源

```bash
helm install kserve oci://ghcr.io/kserve/charts/kserve --version v0.16.0
```

### Install using YAML
使用 YAML 进行安装

Install KServe CRDs and Controller, `--server-side` option is required as the InferenceService CRD is large, see [this issue](https://github.com/kserve/kserve/issues/3487) for details.
安装 KServe CRD 和 Controller, 由于 InferenceService CRD 很大, 因此需要 `--server-side` 选项, 详情请参阅[此问题](https://github.com/kserve/kserve/issues/3487).

```bash
kubectl apply --server-side -f https://github.com/kserve/kserve/releases/download/v0.16.0/kserve.yaml
```

Install KServe Built-in ClusterServingRuntimes
安装 KServe 内置的 ClusterServingRuntimes

```bash
kubectl apply --server-side -f https://github.com/kserve/kserve/releases/download/v0.16.0/kserve-cluster-resources.yaml
```

> note
> **ClusterServingRuntimes** are required to create InferenceService for built-in model serving runtimes with KServe v0.8.0 or higher.
> 要为 KServe v0.8.0 或更高版本内置模型服务运行时创建 InferenceService, 需要 **ClusterServingRuntimes**.
>
