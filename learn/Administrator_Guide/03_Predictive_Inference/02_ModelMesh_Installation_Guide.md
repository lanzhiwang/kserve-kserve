# ModelMesh Installation

* https://kserve.github.io/website/docs/0.16/admin-guide/modelmesh

ModelMesh installation provides high-scale, high-density model serving for scenarios with frequent model changes and large numbers of models, making it particularly well-suited for predictive inference workloads.
ModelMesh 安装为频繁模型变更和大量模型的场景提供高规模、高密度的模型服务, 使其特别适合预测推理工作负载.

It uses a distributed architecture particularly designed for:
它采用分布式架构, 专为以下用途而设计:

- High-scale model serving
  大规模模型服务

- Multi-model management
  多模型管理

- Intelligent model loading
  智能模型加载

- Efficient resource utilization
  高效的资源利用

- Frequent model updates
  频繁的模型更新

## Use Cases

ModelMesh is designed for predictive inference use cases where:
ModelMesh 专为以下预测推理用例而设计:

- You have many models (hundreds to thousands)
  您有很多型号(成百上千种)

- Models are frequently updated or changed
  模型经常更新或更改.

- Resource efficiency is critical
  资源效率至关重要

- You need intelligent model placement and caching
  你需要智能模型放置和缓存

- Model inference times are relatively short
  模型推理时间相对较短

- Models can share computational resources efficiently
  模型可以高效地共享计算资源.

## Prerequisites

- Kubernetes cluster (v1.32+)

- kubectl configured to access your cluster

- Cluster admin permissions

## Installation

### Option 1: Quick Install with KServe
选项 1: 使用 KServe 快速安装

Install KServe with ModelMesh support:
安装支持 ModelMesh 的 KServe:

```bash
curl -s "https://raw.githubusercontent.com/kserve/modelmesh-serving/release-0.12.0/scripts/install.sh" | bash
```

### Option 2: Manual Installation
选项 2: 手动安装

#### 1. Install etcd (for model metadata storage)
安装 etcd(用于模型元数据存储)

```bash
kubectl apply -f https://raw.githubusercontent.com/kserve/modelmesh-serving/release-0.12.0/config/dependencies/etcd.yaml
```

#### 2. Install ModelMesh Serving
安装 ModelMesh Serving

```bash
kubectl apply -f https://raw.githubusercontent.com/kserve/modelmesh-serving/release-0.12.0/config/default/modelmesh-serving.yaml
```

#### 3. Install KServe Controller
安装 KServe 控制器

```bash
kubectl apply -f https://github.com/kserve/kserve/releases/download/v0.16.0/kserve.yaml
```

## Configuration

### Enable ModelMesh Mode
启用模型网格模式

Configure KServe to use ModelMesh:
配置 KServe 使用 ModelMesh:

```bash
kubectl patch configmap inferenceservice-config -n kserve-system -p '{
  "data": {
    "deploy": "{\"defaultDeploymentMode\": \"ModelMesh\"}"
  }
}'
```

### Storage Configuration
存储配置

Configure storage for model repositories:
配置模型存储库的存储:

```bash
apiVersion: v1
kind: Secret
metadata:
  name: model-storage-config
  namespace: modelmesh-serving
data:
  localMinIO: |
    {
      "type": "s3",
      "access_key_id": "minioadmin",
      "secret_access_key": "minioadmin",
      "endpoint_url": "http://minio.minio.svc.cluster.local:9000",
      "default_bucket": "modelmesh-example-models",
      "region": "us-south"
    }
```

## Features

### Intelligent Model Management
智能模型管理

- **Model Caching**: Frequently accessed models stay in memory
  模型缓存: 频繁访问的模型会保留在内存中.

- **LRU Eviction**: Least recently used models are evicted when memory is full
  LRU 驱逐: 当内存已满时, 最近最少使用的模型将被驱逐.

- **Predictive Loading**: Models can be pre-loaded based on usage patterns
  预测性加载: 可以根据使用模式预加载模型

### High Density Serving

- **Resource Sharing**: Multiple models share the same runtime pods
  资源共享: 多个模型共享同一个运行时 pod.

- **Dynamic Loading**: Models are loaded and unloaded as needed
  动态加载: 根据需要加载和卸载模型.

- **Efficient Packing**: Optimal placement of models across available resources
  高效打包: 在可用资源上优化模型放置.

### Performance Optimization
性能优化

- **Fast Model Loading**: Optimized model loading and caching
  快速模型加载: 优化模型加载和缓存

- **Connection Pooling**: Efficient request routing to model instances
  连接池: 高效地将请求路由到模型实例

- **Minimal Overhead**: Low latency model switching
  最小开销: 低延迟模型切换
