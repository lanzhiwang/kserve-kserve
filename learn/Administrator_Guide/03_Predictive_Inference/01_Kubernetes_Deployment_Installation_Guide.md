# Kubernetes Deployment Installation

* https://kserve.github.io/website/docs/0.16/admin-guide/kubernetes-deployment

KServe supports `Standard` mode to enable `InferenceService` deployment for both **Predictive Inference** and **Generative Inference** workloads with **minimal dependencies** on Kubernetes resources.
KServe 支持 `Standard` 模式, 以**最小的 Kubernetes 资源依赖性**, 为**预测推理**和**生成推理工作**负载启用 `InferenceService` 部署.

This approach uses standard Kubernetes resources:
这种方法使用标准的 Kubernetes 资源:

- [`Deployment`](https://kubernetes.io/docs/concepts/workloads/controllers/deployment) for managing container instances
  用于管理容器实例的 [`Deployment`](https://kubernetes.io/docs/concepts/workloads/controllers/deployment)

- [`Service`](https://kubernetes.io/docs/concepts/services-networking/service) for internal communication
  内部沟通 [`Service`](https://kubernetes.io/docs/concepts/services-networking/service)

- [`Ingress`](https://kubernetes.io/docs/concepts/services-networking/ingress) / [`Gateway API`](https://kubernetes.io/docs/concepts/services-networking/gateway/) for external access
  用于外部访问的 [`Ingress`](https://kubernetes.io/docs/concepts/services-networking/ingress) / [`Gateway API`](https://kubernetes.io/docs/concepts/services-networking/gateway/)

- [`Horizontal Pod Autoscaler`](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale) for scaling
  用于扩展的 [`Horizontal Pod Autoscaler`](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale)

Compared to `Knative` mode which depends on Knative for request-driven autoscaling, in `Standard` mode [KEDA](https://keda.sh/) can be installed optionally to enable autoscaling based on any custom metrics. However, note that `Scale from Zero` is currently not supported in `Standard` mode for HTTP requests.
与依赖 Knative 进行请求驱动自动扩缩容的 `Knative` 模式相比, `Standard` 模式可以选择安装 [KEDA](https://keda.sh/), 从而基于任何自定义指标启用自动扩缩容. 但是请注意, `Standard` 模式目前不支持 HTTP 请求的 `Scale from Zero` 功能.

## Installation Requirements

KServe has the following minimum requirements:

- **Kubernetes**: Version 1.32+

- **Cert Manager**: Version 1.15.0+

- **Network Controller**: Choice of Gateway API (recommended) or Ingress controllers

> note
> `Gateway API` is the recommended option for KServe while Ingress API is still supported. Follow the [Gateway API migration guide](https://kserve.github.io/website/docs/0.16/admin-guide/gatewayapi-migration) to migrate from Kubernetes Ingress to Gateway API.
> 对于 KServe, 推荐使用 `Gateway API`, 但 Ingress API 仍然受支持. 请按照 [Gateway API 迁移指南](https://kserve.github.io/website/docs/0.16/admin-guide/gatewayapi-migration), 从 Kubernetes Ingress 迁移到 Gateway API.

## Deployment Considerations
部署注意事项

### For Generative Inference
用于生成推理

Standard Kubernetes deployment is the **recommended approach** for generative inference workloads because it provides:
对于生成式推理工作负载, **推荐采用标准 Kubernetes 部署方式**, 因为它具有以下优势:

- Full control over resource allocation for GPU-accelerated models
  对 GPU 加速模型的资源分配拥有完全控制权

- Better handling of long-running inference requests
  更好地处理长时间运行的推理请求

- More predictable scaling behavior for resource-intensive workloads
  对于资源密集型工作负载, 可实现更可预测的扩展行为

- Support for streaming responses with appropriate networking configuration
  支持通过适当的网络配置进行流式响应

### For Predictive Inference
用于预测推理

Standard Kubernetes deployment is suitable for predictive inference workloads when:
标准 Kubernetes 部署适用于以下预测推理工作负载:

- You need direct control over Kubernetes resources
  您需要直接控制 Kubernetes 资源

- Your models require specific resource configurations
  您的模型需要特定的资源配置.

- You want to use standard Kubernetes scaling mechanisms
  您希望使用标准的 Kubernetes 扩展机制

- You're integrating with existing Kubernetes monitoring solutions
  您正在与现有的 Kubernetes 监控解决方案集成

## Prerequisites

- Kubernetes cluster (v1.32+)

- kubectl configured to access your cluster

- Cluster admin permissions

## Installation

### 1. Install Cert Manager

The minimally required Cert Manager version is 1.15.0 and you can refer to the [Cert Manager installation guide](https://cert-manager.io/docs/installation/).
证书管理器的最低版本要求为 1.15.0, 您可以参考[证书管理器安装指南](https://cert-manager.io/docs/installation/).

> note
> Cert Manager is required to provision webhook certs for production-grade installation. Alternatively, you can run a self-signed certs generation script.
> 生产级安装需要使用证书管理器来配置 Webhook 证书. 或者, 您也可以运行自签名证书生成脚本.
>

### 2. Install Network Controller

#### Gateway API

The Kubernetes Gateway API is a newer, more flexible and standardized way to manage traffic ingress and egress in Kubernetes clusters. KServe implements the Gateway API version `1.2.1`.
Kubernetes Gateway API 是一种更新、更灵活、更标准化的方式来管理 Kubernetes 集群中的流量流入和流出. KServe 实现了 Gateway API `1.2.1` 版本.

The Gateway API is not part of the Kubernetes cluster, therefore it needs to be installed manually:
Gateway API 不属于 Kubernetes 集群的一部分, 因此需要手动安装:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
```

Then, create a `GatewayClass` resource using your preferred network controller. For this example, we will use [Envoy Gateway](https://gateway.envoyproxy.io/docs/):
然后, 使用您首选的网络控制器创建 `GatewayClass` 资源. 在本示例中, 我们将使用 [Envoy Gateway](https://gateway.envoyproxy.io/docs/):

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: envoy
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
```

Create a `Gateway` resource to expose the `InferenceService`:
创建 `Gateway` 资源以公开 `InferenceService`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kserve-ingress-gateway
  namespace: kserve
spec:
  gatewayClassName: envoy
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
    - name: https
      protocol: HTTPS
      port: 443
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: my-secret
            namespace: kserve
      allowedRoutes:
        namespaces:
          from: All
  infrastructure:
    labels:
      serving.kserve.io/gateway: kserve-ingress-gateway
```

> note
> KServe can automatically create a default `Gateway` named `kserve-ingress-gateway` during installation if the Helm value `kserve.controller.gateway.ingressGateway.createGateway` is set to `true`. If you choose to use this default gateway, you can skip creating your own gateway.
> 如果 Helm 文件中 `kserve.controller.gateway.ingressGateway.createGateway` 的值设置为 `true`, KServe 可以在安装过程中自动创建一个名为 `kserve-ingress-gateway` 的默认 `Gateway`. 如果您选择使用此默认网关, 则可以跳过创建您自己的网关.
>

#### Kubernetes Ingress

In this guide, we choose to install Istio as ingress controller. The minimally required Istio version is 1.22 and you can refer to the [Istio install guide](https://istio.io/latest/docs/setup/install).
本指南选择安装 Istio 作为入口控制器. 最低要求的 Istio 版本为 1.22, 您可以参考 [Istio 安装指南](https://istio.io/latest/docs/setup/install).

Once Istio is installed, create `IngressClass` resource for istio:
安装完 Istio 后, 为 Istio 创建 `IngressClass` 资源:

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: istio
spec:
  controller: istio.io/ingress-controller
```

> note
> Istio ingress is recommended, but you can choose to install with other [Ingress controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/) and create `IngressClass` resource for your Ingress option.
> 建议使用 Istio Ingress, 但您也可以选择安装其他 [Ingress 控制器](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/), 并为您的 Ingress 选项创建 `IngressClass` 资源.
>

### 3. Install KServe

> note
> The default KServe deployment mode is `Knative` which depends on Knative. The following step changes the default deployment mode to `Standard` before installing KServe.
> KServe 的默认部署模式为 `Knative`, 它依赖于 Knative. 以下步骤会在安装 KServe 之前将默认部署模式更改为 `Standard`.
>

#### Gateway API with Helm

1. Install KServe CRDs

```bash
helm install kserve-crd oci://ghcr.io/kserve/charts/kserve-crd --version v0.16.0
```

2. Install KServe Resources

Set the `kserve.controller.deploymentMode` to `Standard` and configure the Gateway API:

```bash
helm install kserve oci://ghcr.io/kserve/charts/kserve --version v0.16.0 \
  --set kserve.controller.deploymentMode=Standard \
  --set kserve.controller.gateway.ingressGateway.enableGatewayApi=true \
  --set kserve.controller.gateway.ingressGateway.kserveGateway=kserve/kserve-ingress-gateway
```

#### Gateway API with YAML

1. Install KServe: `--server-side` option is required as the InferenceService CRD is large.
  安装 KServe: 由于 InferenceService CRD 很大, 因此需要 `--server-side` 选项.

```bash
kubectl apply --server-side -f https://github.com/kserve/kserve/releases/download/v0.16.0/kserve.yaml
```

2. Install KServe default serving runtimes:
  安装 KServe 默认服务运行时:

```bash
kubectl apply --server-side -f https://github.com/kserve/kserve/releases/download/v0.16.0/kserve-cluster-resources.yaml
```

3. Change default deployment mode and ingress option
  更改默认部署模式和入口选项

First in the ConfigMap `inferenceservice-config` modify the `defaultDeploymentMode` to `Standard`:

```bash
kubectl patch configmap/inferenceservice-config -n kserve --type=strategic -p '{"data": {"deploy": "{\"defaultDeploymentMode\": \"Standard\"}"}}'
```

Then enable Gateway API and configure the Gateway:
然后启用网关 API 并配置网关:

```bash
kubectl patch configmap/inferenceservice-config -n kserve --type=strategic -p '{"data": {"ingress": "{\"enableGatewayApi\": true, \"kserveIngressGateway\": \"kserve/kserve-ingress-gateway\"}"}}'
```

#### Ingress with Helm

1. Install KServe CRDs

```bash
helm install kserve-crd oci://ghcr.io/kserve/charts/kserve-crd --version v0.16.0
```

2. Install KServe Resources

Set the `kserve.controller.deploymentMode` to `Standard` and configure the Ingress class:

```bash
helm install kserve oci://ghcr.io/kserve/charts/kserve --version v0.16.0 \
  --set kserve.controller.deploymentMode=Standard \
  --set kserve.controller.gateway.ingressGateway.className=istio
```

#### Ingress with YAML

1. Install KServe: `--server-side` option is required as the InferenceService CRD is large.
  安装 KServe: 由于 InferenceService CRD 很大, 因此需要 `--server-side` 选项.

```bash
kubectl apply --server-side -f https://github.com/kserve/kserve/releases/download/v0.16.0/kserve.yaml
```

2. Install KServe default serving runtimes:

```bash
kubectl apply --server-side -f https://github.com/kserve/kserve/releases/download/v0.16.0/kserve-cluster-resources.yaml
```

3. Change default deployment mode and ingress option

First in the ConfigMap `inferenceservice-config` modify the `defaultDeploymentMode` to `Standard`:

```bash
kubectl patch configmap/inferenceservice-config -n kserve --type=strategic -p '{"data": {"deploy": "{\"defaultDeploymentMode\": \"Standard\"}"}}'
```

Then configure the Ingress class:

```bash
kubectl patch configmap/inferenceservice-config -n kserve --type=strategic -p '{"data": {"ingress": "{\"ingressClassName\": \"istio\"}"}}'
```

## Features

### Standard Mode

In standard mode, KServe creates:
在标准模式下, KServe 会创建:

- Kubernetes Deployments instead of Knative Services
  使用 Kubernetes 部署而不是 Knative 服务

- Standard Kubernetes Services for networking
  用于网络的标准 Kubernetes 服务

- Ingress resources for external access
  用于外部访问的入口资源

- HorizontalPodAutoscaler for scaling
  Horizo​​ntalPodAutoscaler 用于扩展

### Benefits

- **Simplicity**: No dependency on Knative or Istio
  简单易用: 不依赖 Knative 或 Istio

- **Control**: Direct control over Kubernetes resources
  控制: 直接控制 Kubernetes 资源

- **Compatibility**: Works with standard Kubernetes tooling
  兼容性: 与标准 Kubernetes 工具兼容

- **Predictability**: No serverless overhead
  可预测性: 无服务器开销

## Verification

Check that all components are running:
检查所有组件是否都在运行:

```bash
kubectl get pods -n kserve
kubectl get crd | grep serving.kserve.io
```

Expected Output

```bash
NAME          URL                                   READY   PREV   LATEST   PREVROLLEDOUTREVISION   LATESTREADYREVISION                    AGE
sklearn-iris  http://sklearn-iris.default.svc.cluster.local   True           100                        sklearn-iris-predictor-default-00001   5m
```

## Next Steps

- [Deploy your first GenAI InferenceService](https://kserve.github.io/website/docs/0.16/getting-started/genai-first-isvc).

- [Deploy your first Predictive InferenceService](https://kserve.github.io/website/docs/0.16/getting-started/predictive-first-isvc).

- Configure [auto-scaling](https://kserve.github.io/website/docs/0.16/model-serving/generative-inference/autoscaling) for your GenAI models.
