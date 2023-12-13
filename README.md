# KServe

[![go.dev reference](https://img.shields.io/badge/go.dev-reference-007d9c?logo=go&logoColor=white)](https://pkg.go.dev/github.com/kserve/kserve)
[![Coverage Status](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/andyi2it/5174bd748ac63a6e4803afea902e9810/raw/coverage.json)](https://github.com/kserve/kserve/actions/workflows/go.yml)
[![Go Report Card](https://goreportcard.com/badge/github.com/kserve/kserve)](https://goreportcard.com/report/github.com/kserve/kserve)
[![OpenSSF Best Practices](https://bestpractices.coreinfrastructure.org/projects/6643/badge)](https://bestpractices.coreinfrastructure.org/projects/6643)
[![Releases](https://img.shields.io/github/release-pre/kserve/kserve.svg?sort=semver)](https://github.com/kserve/kserve/releases)
[![LICENSE](https://img.shields.io/github/license/kserve/kserve.svg)](https://github.com/kserve/kserve/blob/master/LICENSE)
[![Slack Status](https://img.shields.io/badge/slack-join_chat-white.svg?logo=slack&style=social)](https://kubeflow.slack.com/archives/CH6E58LNP)

KServe provides a Kubernetes [Custom Resource Definition](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) for serving machine learning (ML) models on arbitrary frameworks. It aims to solve production model serving use cases by providing performant, high abstraction interfaces for common ML frameworks like Tensorflow, XGBoost, ScikitLearn, PyTorch, and ONNX.
KServe 提供了 Kubernetes 自定义资源定义，用于在任意框架上提供机器学习 (ML) 模型。 它旨在通过为 Tensorflow、XGBoost、ScikitLearn、PyTorch 和 ONNX 等常见 ML 框架提供高性能、高抽象接口来解决生产模型服务用例。

It encapsulates the complexity of autoscaling, networking, health checking, and server configuration to bring cutting edge serving features like GPU Autoscaling, Scale to Zero, and Canary Rollouts to your ML deployments. It enables a simple, pluggable, and complete story for Production ML Serving including prediction, pre-processing, post-processing and explainability. KServe is being [used across various organizations.](https://kserve.github.io/website/master/community/adopters/)
它封装了自动缩放、网络、运行状况检查和服务器配置的复杂性，为您的 ML 部署带来 GPU 自动缩放、缩放到零和金丝雀部署等尖端服务功能。 它为生产 ML 服务提供了一个简单、可插入且完整的故事，包括预测、预处理、后处理和可解释性。 KServe 正在多个组织中使用。

For more details, visit the [KServe website](https://kserve.github.io/website/).
欲了解更多详情，请访问 KServe 网站。

![KServe](/docs/diagrams/kserve.png)

_Since 0.7 [KFServing is rebranded to KServe](https://blog.kubeflow.org/release/official/2021/09/27/kfserving-transition.html), we still support the RTS release
[0.6.x](https://github.com/kserve/kserve/tree/release-0.6), please refer to corresponding release branch for docs_.
由于 0.7 KFServing 更名为 KServe，我们仍然支持 RTS 版本 0.6.x，请参阅相应版本分支的文档。

### Why KServe?
- KServe is a standard, cloud agnostic **Model Inference Platform** on Kubernetes, built for highly scalable use cases.
  KServe 是 Kubernetes 上的标准、与云无关的模型推理平台，专为高度可扩展的用例而构建。

- Provides performant, **standardized inference protocol** across ML frameworks.
  跨 ML 框架提供高性能、标准化的推理协议。

- Support modern **serverless inference workload** with **request based autoscaling including scale-to-zero** on **CPU and GPU**.
  通过基于请求的自动缩放（包括 CPU 和 GPU 上的缩放至零）支持现代无服务器推理工作负载。

- Provides **high scalability, density packing and intelligent routing** using **ModelMesh**.
  使用 ModelMesh 提供高可扩展性、密度封装和智能路由。

- **Simple and pluggable production serving** for **inference**, **pre/post processing**, **monitoring** and **explainability**.
  简单且可插入的生产服务于推理、前/后处理、监控和可解释性。

- Advanced deployments for **canary rollout**, **pipeline**, **ensembles** with **InferenceGraph**.
  金丝雀部署、管道、InferenceGraph 集成的高级部署。

### Learn More
了解更多

To learn more about KServe, how to use various supported features, and how to participate in the KServe community,
please follow the [KServe website documentation](https://kserve.github.io/website).
Additionally, we have compiled a list of [presentations and demos](https://kserve.github.io/website/master/community/presentations/) to dive through various details.
要了解有关 KServe、如何使用各种支持的功能以及如何参与 KServe 社区的更多信息，请关注 KServe 网站文档。 此外，我们还编制了一系列演示和演示，以深入了解各种细节。

### :hammer_and_wrench: Installation

#### Standalone Installation
独立安装

- **[Serverless Installation](https://kserve.github.io/website/master/admin/serverless/serverless/)**: KServe by default installs Knative for **serverless deployment** for InferenceService.
  无服务器安装：KServe 默认安装 Knative，用于 InferenceService 的无服务器部署。

- **[Raw Deployment Installation](https://kserve.github.io/website/master/admin/kubernetes_deployment)**: Compared to Serverless Installation, this is a more **lightweight** installation. However, this option does not support canary deployment and request based autoscaling with scale-to-zero.
  原始部署安装：与无服务器安装相比，这是一种更轻量级的安装。 但是，此选项不支持金丝雀部署和基于请求的自动缩放（缩放为零）。

- **[ModelMesh Installation](https://kserve.github.io/website/master/admin/modelmesh/)**: You can optionally install ModelMesh to enable **high-scale**, **high-density** and **frequently-changing model serving** use cases.
  ModelMesh 安装：您可以选择安装 ModelMesh，以实现高规模、高密度和频繁更改的模型服务用例。

- **[Quick Installation](https://kserve.github.io/website/master/get_started/)**: Install KServe on your local machine.
  快速安装：在本地计算机上安装 KServe。

#### Kubeflow Installation

KServe is an important addon component of Kubeflow, please learn more from the [Kubeflow KServe documentation](https://www.kubeflow.org/docs/external-add-ons/kserve/kserve) and follow [KServe with Kubeflow on AWS](https://awslabs.github.io/kubeflow-manifests/main/docs/component-guides/kserve) to learn how to use KServe on AWS.
KServe 是 Kubeflow 的重要插件组件，请参阅 Kubeflow KServe 文档了解更多信息，并关注 KServe with Kubeflow on AWS 以了解如何在 AWS 上使用 KServe。

### :flight_departure: [Create your first InferenceService](https://kserve.github.io/website/master/get_started/first_isvc)
创建您的第一个 InferenceService

### :bulb: [Roadmap](./ROADMAP.md)
路线图

### :blue_book: [InferenceService API Reference](https://kserve.github.io/website/master/reference/api/)
InferenceService API 参考

### :toolbox: [Developer Guide](https://kserve.github.io/website/master/developer/developer/)
开发者指南

### :writing_hand: [Contributor Guide](./CONTRIBUTING.md)
贡献者指南

### :handshake: [Adopters](https://kserve.github.io/website/master/community/adopters/)
采用者
