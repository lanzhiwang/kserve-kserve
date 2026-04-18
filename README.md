# KServe
[![go.dev reference](https://img.shields.io/badge/go.dev-reference-007d9c?logo=go&logoColor=white)](https://pkg.go.dev/github.com/kserve/kserve)
[![Coverage Status](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/andyi2it/5174bd748ac63a6e4803afea902e9810/raw/coverage.json)](https://github.com/kserve/kserve/actions/workflows/go.yml)
[![Go Report Card](https://goreportcard.com/badge/github.com/kserve/kserve)](https://goreportcard.com/report/github.com/kserve/kserve)
[![OpenSSF Best Practices](https://bestpractices.coreinfrastructure.org/projects/6643/badge)](https://bestpractices.coreinfrastructure.org/projects/6643)
[![Releases](https://img.shields.io/github/release-pre/kserve/kserve.svg?sort=semver)](https://github.com/kserve/kserve/releases)
[![LICENSE](https://img.shields.io/github/license/kserve/kserve.svg)](https://github.com/kserve/kserve/blob/master/LICENSE)
[![Slack Status](https://img.shields.io/badge/slack-join_chat-white.svg?logo=slack&style=social)](https://github.com/kserve/community/blob/main/README.md#questions-and-issues)
[![Gurubase](https://img.shields.io/badge/Gurubase-Ask%20KServe%20Guru-006BFF)](https://gurubase.io/g/kserve)

KServe is a standardized distributed generative and predictive AI inference platform for scalable, multi-framework deployment on Kubernetes.
KServe 是一个标准化的分布式生成式和预测式 AI 推理平台, 可在 Kubernetes 上进行可扩展的多框架部署.

KServe is being [used by many organizations](https://kserve.github.io/website/docs/community/adopters) and is a [Cloud Native Computing Foundation (CNCF)](https://www.cncf.io/) incubating project.
KServe 已被许多组织使用, 并且是云原生计算基金会 (CNCF) 的孵化项目.

For more details, visit the [KServe website](https://kserve.github.io/website/).
更多详情请访问 KServe 网站.

![KServe](/docs/diagrams/kserve_new.png)

### Why KServe?

Single platform that unifies Generative and Predictive AI inference on Kubernetes. Simple enough for quick deployments, yet powerful enough to handle enterprise-scale AI workloads with advanced features.
一个统一的平台, 在 Kubernetes 上实现生成式和预测式 AI 推理. 它既足够简单, 可以快速部署, 又足够强大, 能够处理企业级 AI 工作负载并提供高级功能.

### Features

**Generative AI**

  * 🧮 **Optimized Backends**: Support for vLLM and llm-d for optimized performance for serving LLMs
    🧮 优化后端: 支持 vLLM 和 llm-d, 以优化 LLM 服务性能

  * 📌 **Standardization**: OpenAI-compatible inference protocol for seamless integration with LLMs
    📌 标准化: 与 OpenAI 兼容的推理协议, 可与 LLM 无缝集成

  * 🚅 **GPU Acceleration**: High-performance serving with GPU support and optimized memory management for large models
    🚅 GPU 加速: 利用 GPU 支持和针对大型模型优化的内存管理, 实现高性能服务

  * 💾 **Model Caching**: Intelligent model caching to reduce loading times and improve response latency for frequently used models
    💾 模型缓存: 智能模型缓存, 可减少加载时间并改善常用模型的响应延迟

  * 🗂️ **KV Cache Offloading**: Advanced memory management with KV cache offloading to CPU/disk for handling longer sequences efficiently
    🗂️ KV 缓存卸载: 通过将 KV 缓存卸载到 CPU/磁盘, 实现高级内存管理, 从而高效处理更长的序列.

  * 📈 **Autoscaling**: Request-based autoscaling capabilities optimized for generative workload patterns
    📈 自动扩缩容: 基于请求的自动扩缩容功能, 针对生成式工作负载模式进行了优化

  * 🔧 **Hugging Face Ready**: Native support for Hugging Face models with streamlined deployment workflows
    🔧 Hugging Face 就绪: 原生支持 Hugging Face 模型, 并简化部署工作流程

**Predictive AI**

  * 🧮 **Multi-Framework**: Support for TensorFlow, PyTorch, scikit-learn, XGBoost, ONNX, and more
    🧮 多框架: 支持 TensorFlow、PyTorch、scikit-learn、XGBoost、ONNX 等.

  * 🔀 **Intelligent Routing**: Seamless request routing between predictor, transformer, and explainer components with automatic traffic management
    🔀 智能路由: 在预测器、转换器和解释器组件之间实现无缝请求路由, 并自动管理流量

  * 🔄 **Advanced Deployments**: Canary rollouts, inference pipelines, and ensembles with InferenceGraph
    🔄 高级部署: 使用 InferenceGraph 实现金丝雀发布、推理管道和集成模型

  * ⚡ **Autoscaling**: Request-based autoscaling with scale-to-zero for predictive workloads
    ⚡ 自动扩缩容: 基于请求的自动扩缩容, 支持预测性工作负载的零缩容

  * 🔍 **Model Explainability**: Built-in support for model explanations and feature attribution to understand prediction reasoning
    🔍 模型可解释性: 内置模型解释和特征归因支持, 以理解预测推理

  * 📊 **Advanced Monitoring**: Enables payload logging, outlier detection, adversarial detection, and drift detection
    📊 高级监控: 支持有效载荷日志记录、异常值检测、对抗性检测和漂移检测

  * 💰 **Cost Efficient**: Scale-to-zero on expensive resources when not in use, reducing infrastructure costs
   💰 成本效益高: 不使用时可完全停止占用昂贵资源, 从而降低基础设施成本.

### Learn More
To learn more about KServe, how to use various supported features, and how to participate in the KServe community, please follow the [KServe website documentation](https://kserve.github.io/website). Additionally, we have compiled a list of [presentations and demos](https://kserve.github.io/website/docs/community/presentations) to dive through various details.
要了解更多关于 KServe 的信息, 包括如何使用各项支持的功能以及如何参与 KServe 社区, 请参阅 KServe 网站文档. 此外, 我们还整理了一系列演示文稿和演示,  方便您深入了解各种细节.

### :hammer_and_wrench: Installation

#### Standalone Installation
- **[Standard Kubernetes Installation](https://kserve.github.io/website/docs/admin-guide/overview#raw-kubernetes-deployment)**: Compared to Serverless Installation, this is a more **lightweight** installation. However, this option does not support canary deployment and request based autoscaling with scale-to-zero.
  标准 Kubernetes 安装: 与 Serverless 安装相比, 这种安装方式更为轻量级. 但是, 此选项不支持金丝雀部署和基于请求的零缩减自动扩缩容.

- **[Knative Installation](https://kserve.github.io/website/docs/admin-guide/overview#serverless-deployment)**: KServe by default installs Knative for **serverless deployment** for InferenceService.
  Knative 安装: KServe 默认安装 Knative, 用于 InferenceService 的无服务器部署.

- **[ModelMesh Installation](https://kserve.github.io/website/docs/admin-guide/overview#modelmesh-deployment)**: You can optionally install ModelMesh to enable **high-scale**, **high-density** and **frequently-changing model serving** use cases.
  ModelMesh 安装: 您可以选择安装 ModelMesh, 以支持高规模 、 高密度和频繁变化的模型服务用例.

- **[Quick Installation](https://kserve.github.io/website/docs/getting-started/quickstart-guide)**: Install KServe on your local machine.
  快速安装: 在本地计算机上安装 KServe.

#### Kubeflow Installation
KServe is an important addon component of Kubeflow, please learn more from the [Kubeflow KServe documentation](https://www.kubeflow.org/docs/external-add-ons/kserve/kserve). Check out the following guides for running [on AWS](https://awslabs.github.io/kubeflow-manifests/main/docs/component-guides/kserve) or [on OpenShift Container Platform](https://github.com/kserve/kserve/blob/master/docs/OPENSHIFT_GUIDE.md).

### :flight_departure: [Create your first InferenceService](https://kserve.github.io/website/docs/getting-started/genai-first-isvc)

### :bulb: [Roadmap](./ROADMAP.md)

### :blue_book: [InferenceService API Reference](https://kserve.github.io/website/docs/reference/crd-api)

### :toolbox: [Developer Guide](https://kserve.github.io/website/docs/developer-guide)

### :writing_hand: [Contributor Guide](https://kserve.github.io/website/docs/developer-guide/contribution)

### :handshake: [Adopters](https://kserve.github.io/website/docs/community/adopters)

### Star History

[![Star History Chart](https://api.star-history.com/svg?repos=kserve/kserve&type=Date)](https://www.star-history.com/#kserve/kserve&Date)

### Contributors

Thanks to all of our amazing contributors!

<a href="https://github.com/kserve/kserve/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=kserve/kserve" />
</a>
