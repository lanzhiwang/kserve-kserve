# KServe Administrator Guide

* https://kserve.github.io/website/docs/0.16/admin-guide/overview

This guide provides a comprehensive overview of KServe administration tasks and responsibilities. It covers installation options, configuration settings, and best practices for managing KServe in production environments, with specific guidance for both predictive and generative inference workloads.
本指南全面概述了 KServe 的管理任务和职责. 内容涵盖安装选项、配置设置以及在生产环境中管理 KServe 的最佳实践, 并针对预测推理和生成推理工作负载提供了具体指导.

## Introduction

KServe is a standard model inference platform on Kubernetes, providing high-performance, high-scale model serving solutions. As an administrator, you'll be responsible for installing, configuring, and maintaining KServe in your cluster environment.
KServe 是一个基于 Kubernetes 的标准模型推理平台, 提供高性能、高扩展性的模型服务解决方案. 作为管理员, 您将负责在集群环境中安装、配置和维护 KServe.

The administrator guide helps you understand:
管理员指南可帮助您了解:

- Different deployment options for KServe
  KServe 的不同部署选项

- Configuration best practices for different inference types
  不同推理类型的配置最佳实践

- Maintenance and operational tasks
  维护和操作任务

- Integration with Kubernetes networking components
  与 Kubernetes 网络组件集成

If you are familiar with KServe, you can skip the introductory sections and jump directly to the relevant [deployment guides](https://kserve.github.io/website/docs/0.16/admin-guide/overview#installation).
如果您熟悉 KServe, 您可以跳过介绍部分, 直接跳转到相关的部署指南.

## Inference Types

KServe supports two primary model inference types, each with specific deployment considerations:
KServe 支持两种主要的模型推理类型, 每种类型都有其特定的部署注意事项:

### Generative Inference

Generative inference workloads involve models that generate new content (text, images, audio, etc.) based on input prompts. These models typically:
生成式推理工作负载涉及根据输入提示生成新内容(文本、图像、音频等)的模型. 这些模型通常:

- Require significantly more computational resources
  需要更多的计算资源

- Have longer inference times
  推理时间更长

- Need GPU acceleration
  需要 GPU 加速

- Process streaming responses
  流程流响应

- Have higher memory requirements
  内存需求较高

**Recommended deployment option**: For generative inference workloads, the **Standard Kubernetes Deployment** approach is recommended as it provides the most control over resource allocation and scaling. Gateway API is particularly recommended for generative inference to handle streaming responses effectively.
**推荐部署方案**: 对于生成式推理工作负载, 建议采用**标准 Kubernetes 部署**方案, 因为它能更好地控制资源分配和扩展. 尤其推荐使用 Gateway API 来高效处理流式响应, 尤其适用于生成式推理.

### Predictive Inference

Predictive inference workloads involve models that predict specific values or classifications based on input data. These models typically:
预测推理工作负载涉及基于输入数据预测特定值或分类的模型. 这些模型通常:

- Have shorter inference times
  缩短推理时间

- Can often run on CPU
  通常可以在 CPU 上运行

- Require less memory
  所需内存更少

- Have more predictable resource usage patterns
  拥有更可预测的资源使用模式

- Return fixed-size responses
  返回固定大小的响应

**Available deployment options**: For predictive inference workloads, KServe offers multiple deployment options:
**可用的部署选项**: 对于预测推理工作负载, KServe 提供多种部署选项:

- **Standard Kubernetes Deployment**: For direct control over resources
  **标准 Kubernetes 部署**: 用于直接控制资源

- **Knative Deployment**: For scale to zero capabilities and cost optimization
  **原生部署**: 实现零扩展能力和成本优化

- **ModelMesh Deployment**: For high-density, multi-model scenarios
  **模型网格部署**: 适用于高密度、多模型场景

## Installation

KServe can be installed using one of three supported deployment modes. This Installation sections describe what each mode is best for, the common prerequisites, and how to choose the correct guide for your workload.
KServe 可通过三种受支持的部署模式之一进行安装. 本安装部分将介绍每种模式的最佳用途、常见先决条件以及如何为您的工作负载选择正确的指南.

- **[Install with Standard Kubernetes Deployment](https://kserve.github.io/website/docs/0.16/admin-guide/kubernetes-deployment)** - suitable for both generative and predictive inference workloads
  使用标准 Kubernetes 部署进行安装 - 适用于生成式和预测式推理工作负载

- **[Install with Knative Deployment](https://kserve.github.io/website/docs/0.16/admin-guide/serverless)** - suitable for burst and unpredictable traffic workloads with scale to zero features for cost optimization.
  使用 Knative Deployment 进行安装 - 适用于突发性和不可预测的流量工作负载, 并具有零扩展功能以优化成本.

- **[Install with ModelMesh Deployment](https://kserve.github.io/website/docs/0.16/admin-guide/modelmesh)** - suitable for high-density, multi-model scenarios
  使用 ModelMesh Deployment 进行安装 - 适用于高密度、多模型场景

## Networking Configuration

### Gateway API Migration

> tip
> Gateway API is particularly recommended for generative inference workloads to better handle streaming responses and long-lived connections.
> 网关 API 特别推荐用于生成式推理工作负载, 以便更好地处理流式响应和长时间连接.
>

KServe recommends using the Gateway API for network configuration. The Gateway API provides a more flexible and standardized way to manage traffic ingress and egress in Kubernetes clusters compared to traditional Ingress resources.
KServe 建议使用 Gateway API 进行网络配置. 与传统的 Ingress 资源相比, Gateway API 提供了一种更灵活、更标准化的方式来管理 Kubernetes 集群中的流量入站和出站.

The migration process involves:
迁移过程包括:

1. Installing Gateway API CRDs
  安装网关 API CRD

2. Creating appropriate GatewayClass resources
  创建合适的 GatewayClass 资源

3. Configuring Gateway and HTTPRoute resources
  配置网关和 HTTP 路由资源

4. Updating KServe to use the Gateway API
  更新 KServe 以使用网关 API

[Learn more about Gateway API Migration](https://kserve.github.io/website/docs/0.16/admin-guide/gatewayapi-migration)

## Best Practices

When administering KServe, consider these best practices:
在管理 KServe 时, 请考虑以下最佳实践:

### For All Inference Types

- **Security Configuration**: Use proper authentication and network policies
  安全配置: 使用正确的身份验证和网络策略

- **Monitoring**: Set up monitoring for KServe components and model performance
  监控: 设置对 KServe 组件和模型性能的监控

- **Networking**: Configure appropriate timeouts and retry strategies for model inference
  网络: 为模型推理配置合适的超时和重试策略

### For Generative Inference

- **Resource Planning**: Ensure adequate GPU resources are available
  资源规划: 确保有足够的 GPU 资源可用

- **Memory Configuration**: Set higher memory limits and requests
  内存配置: 设置更高的内存限制和请求

- **Network Configuration**: Use Gateway API for improved streaming capabilities
  网络配置: 使用网关 API 以提高流媒体播放能力

- **Timeout Settings**: Configure longer timeouts to accommodate generation time
  超时设置: 配置更长的超时时间以适应生成时间

### For Predictive Inference

- **Autoscaling**: Configure appropriate scaling thresholds based on model performance
  自动缩放: 根据模型性能配置合适的缩放阈值

- **Resource Efficiency**: Consider Knative or ModelMesh for cost optimization
  资源效率: 考虑使用 Knative 或 ModelMesh 进行成本优化

- **Batch Processing**: Configure batch settings for improved throughput when applicable
  批量处理: 根据需要配置批量设置以提高吞吐量

## Next Steps

Choose one of the detailed guides to proceed with KServe administration based on your inference workload:
根据您的推理工作负载, 选择以下详细指南之一来继续进行 KServe 管理:

### For Generative Inference

- [Standard Kubernetes Deployment Guide](https://kserve.github.io/website/docs/0.16/admin-guide/kubernetes-deployment)
- [Gateway API Migration Guide](https://kserve.github.io/website/docs/0.16/admin-guide/gatewayapi-migration)

### For Predictive Inference

- [Standard Kubernetes Deployment Guide](https://kserve.github.io/website/docs/0.16/admin-guide/kubernetes-deployment)
- [Knative Deployment Guide](https://kserve.github.io/website/docs/0.16/admin-guide/serverless)
- [ModelMesh Deployment Guide](https://kserve.github.io/website/docs/0.16/admin-guide/modelmesh)
- [Gateway API Migration Guide](https://kserve.github.io/website/docs/0.16/admin-guide/gatewayapi-migration)
