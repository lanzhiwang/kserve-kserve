# Deploy Your First GenAI Service

部署您的第一代人工智能服务

In this tutorial, you will deploy a Large Language Model (LLM) using KServe's InferenceService to create a powerful generative AI service. We'll use the Qwen model, a state-of-the-art language model developed by Alibaba, capable of understanding and generating human-like text across multiple languages.  
在本教程中, 您将使用 KServe 的 InferenceService 部署大型语言模型 (LLM), 从而创建一个强大的生成式 AI 服务. 我们将使用 Qwen 模型, 这是一款由阿里巴巴开发的先进语言模型, 能够理解并生成多种语言的类人文本. 

You will learn how to deploy the model and interact with it using OpenAI-compatible APIs, making it easy to integrate with existing applications and tools that support the OpenAI standard.  
您将学习如何部署模型并使用与 OpenAI 兼容的 API 与之交互, 从而轻松地将其集成到支持 OpenAI 标准的现有应用程序和工具中. 

Since your LLM is deployed as an InferenceService rather than a basic Kubernetes deployment, you automatically get enterprise-grade features like **autoscaling**, **load balancing**, **canary deployments**, and **GPU acceleration** out of the box 🚀.  
由于您的 LLM 是作为推理服务部署的, 而不是作为基本的 Kubernetes 部署, 因此您可以自动获得企业级功能, 例如**自动扩缩容** 、 **负载均衡** 、 **金丝雀部署**和 **GPU 加速** 🚀. 

### Prerequisites  先决条件

Before you begin, ensure you have followed the [KServe Quickstart Guide](https://kserve.github.io/website/docs/getting-started/quickstart-guide) to set up KServe in your Kubernetes cluster. This guide assumes you have a working KServe installation and a Kubernetes cluster ready for deployment.  
开始之前, 请确保您已按照 [KServe 快速入门指南](https://kserve.github.io/website/docs/getting-started/quickstart-guide)在 Kubernetes 集群中配置好 KServe. 本指南假设您已成功安装 KServe 并准备好部署所需的 Kubernetes 集群. 

tip  提示

KServe recommends Standard Deployment for Generative AI use cases.  
KServe 建议对生成式人工智能用例采用标准部署. 

### 1. Create a namespace  1. 创建命名空间

First, create a namespace to use for deploying KServe resources:  
首先, 创建一个用于部署 KServe 资源的命名空间: 

```
kubectl create namespace kserve-test
```

### 2. Create an `InferenceService`

2. 创建 `InferenceService`

Create an InferenceService to deploy the Qwen LLM model. This model will be served using KServe's Hugging Face runtime with vLLM backend for optimized performance.  
创建 InferenceService 以部署 Qwen LLM 模型. 该模型将使用 KServe 的 Hugging Face 运行时和 vLLM 后端进行服务, 以优化性能. 

warning  警告

Do not deploy `InferenceServices` in control plane namespaces (i.e. namespaces with `control-plane` label). The webhook is configured in a way to skip these namespaces to avoid any privilege escalations. Deploying InferenceServices to these namespaces will result in the storage initializer not being injected into the pod, causing the pod to fail with the error `No such file or directory: '/mnt/models'`.  
请勿在控制平面命名空间(即带有 `control-plane` 标签的命名空间)中部署 `InferenceServices` 配置为跳过这些命名空间, 以避免任何权限提升. 将 InferenceServices 部署到这些命名空间会导致存储初始化程序无法注入到 pod 中, 从而导致 pod 失败并出现错误 `No such file or directory: '/mnt/models'`. 

- Apply from stdin  从标准输入应用
- Yaml

```
kubectl apply -n kserve-test -f - <<EOFapiVersion: "serving.kserve.io/v1beta1"kind: "InferenceService"metadata:  name: "qwen-llm"  namespace: kserve-testspec:  predictor:    model:      modelFormat:        name: huggingface      args:        - --model_name=qwen      storageUri: "hf://Qwen/Qwen2.5-0.5B-Instruct"      resources:        limits:          cpu: "2"          memory: 6Gi          nvidia.com/gpu: "1"        requests:          cpu: "1"          memory: 4Gi          nvidia.com/gpu: "1"EOF
```

Using Hugging Face Token  使用拥抱脸代币

If you need to authenticate with Hugging Face, first create a secret:  
如果您需要使用 Hugging Face 进行身份验证, 请先创建一个密钥: 

```
kubectl create secret generic hf-secret \--from-literal=HF_TOKEN=your_hf_token_here \-n kserve-test
```

Then create a `clusterstoragecontainer` resource with the secret reference:  
然后使用密钥引用创建 `clusterstoragecontainer` 资源: 

```
apiVersion: "serving.kserve.io/v1alpha1"kind: ClusterStorageContainermetadata:  name: hf-hubspec:  container:    name: storage-initializer    image: kserve/storage-initializer:latest    env:    - name: HF_TOKEN      valueFrom:        secretKeyRef:          name: hf-secret          key: HF_TOKEN          optional: false    resources:      requests:        memory: 2Gi        cpu: "1"      limits:        memory: 4Gi        cpu: "1"  supportedUriFormats:    - prefix: hf://
```

### 3. Check `InferenceService` status.

3. 检查 `InferenceService` 状态. 

```
kubectl get inferenceservices qwen-llm -n kserve-test
```

Expected Output  预期输出

```
NAME       URL                                             READY   PREV   LATEST   PREVROLLEDOUTREVISION   LATESTREADYREVISION                AGEqwen-llm   http://qwen-llm.kserve-test.example.com         True           100                              qwen-llm-predictor-default-47q2g   7d23h
```

If your DNS contains example.com please consult your admin for configuring DNS or using [custom domain](https://knative.dev/docs/serving/using-a-custom-domain).  
如果您的 DNS 中包含 example.com, 请咨询您的管理员以配置 DNS 或使用[自定义域名](https://knative.dev/docs/serving/using-a-custom-domain). 

### 4. Determine the ingress IP and ports

4. 确定入口 IP 地址和端口

Execute the following command to determine if your Kubernetes cluster is running in an environment that supports external load balancers  
执行以下命令以确定您的 Kubernetes 集群是否运行在支持外部负载均衡器的环境中. 

```
kubectl get svc istio-ingressgateway -n istio-system
```

Expected Output  预期输出

```
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)   AGEistio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121   ...       17h
```

- Load Balancer  负载均衡器
- Node Port  节点端口
- Port Forward  端口转发

If the EXTERNAL-IP value is set, your environment has an external load balancer that you can use for the ingress gateway.  
如果设置了 EXTERNAL-IP 值, 则您的环境中有一个外部负载均衡器, 您可以将其用作入口网关. 

```
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
```

### 5. Perform inference  5. 进行推理

Create a JSON file named `chat-input.json` with the following content to send a chat completion request to the Qwen model:  
创建一个名为 `chat-input.json` 的 JSON 文件, 内容如下, 用于向 Qwen 模型发送聊天完成请求: 

```
cat <<EOF > "./chat-input.json"{  "model": "qwen",  "messages": [    {      "role": "system",      "content": "You are a helpful assistant that provides clear and concise answers."    },    {      "role": "user",      "content": "Write a short poem about artificial intelligence and machine learning."    }  ],  "max_tokens": 150,  "temperature": 0.7,  "stream": false}EOF
```

Depending on your setup, use one of the following commands to curl the `InferenceService`:  
根据您的设置, 使用以下命令之一来 curl `InferenceService` : 

- Real DNS  真实域名系统
- Magic DNS  魔法 DNS
- From Ingress gateway with HOST Header  来自带有 HOST 标头的 Ingress 网关
- From local cluster gateway  从本地集群网关
- OpenAI Python Client  OpenAI Python 客户端

```
curl -v -H "Content-Type: application/json" http://qwen-llm.kserve-test.example.com/openai/v1/chat/completions -d @./chat-input.json
```

You should see a response similar to the following, which contains the generated text from the Qwen model:  
您应该会看到类似以下内容的响应, 其中包含 Qwen 模型生成的文本: 

```
{  "id": "cmpl-generated-id",  "object": "chat.completion",  "created": 1703123456,  "model": "qwen",  "choices": [    {      "index": 0,      "message": {        "role": "assistant",        "content": "Here's a poem about artificial intelligence and machine learning:\n\nSilicon minds awakening bright,\nThrough data streams and neural flight,\nPatterns learned from endless code,\nAI walks the digital road.\n\nMachine learning, wise and true,\nFinds the answers we pursue,\nIn the dance of ones and zeros,\nTechnology becomes our heroes."      },      "finish_reason": "stop"    }  ],  "usage": {    "prompt_tokens": 45,    "completion_tokens": 67,    "total_tokens": 112  }}
```

### 6. Clean up  6. 清理

To clean up the resources created in this tutorial, delete the InferenceService and the namespace:  
要清理本教程中创建的资源, 请删除 InferenceService 和命名空间: 

```
kubectl delete inferenceservice qwen-llm -n kserve-testkubectl delete namespace kserve-test
```

### 7. Next Steps  7. 后续步骤

Now that you have successfully deployed a generative AI service using KServe, you can explore more advanced features such as:  
现在您已使用 KServe 成功部署了生成式 AI 服务, 接下来您可以探索更多高级功能, 例如: 

- 📖 **[KServe Concepts](https://kserve.github.io/website/docs/concepts)** - Learn about the core concepts of KServe.  
  📖 **[KServe 概念](https://kserve.github.io/website/docs/concepts)** - 了解 KServe 的核心概念. 
- 📖 **[Supported Tasks](https://kserve.github.io/website/docs/model-serving/generative-inference/overview#supported-generative-tasks)** - Discover the various tasks that KServe can handle.  
  📖 **[支持的任务](https://kserve.github.io/website/docs/model-serving/generative-inference/overview#supported-generative-tasks)** - 了解 KServe 可以处理的各种任务. 
- 📖 **[Autoscaling](https://kserve.github.io/website/docs/model-serving/generative-inference/autoscaling)**: Automatically scale your service based on traffic and resource usage / metrics. 
  📖 **[自动扩缩容](https://kserve.github.io/website/docs/model-serving/generative-inference/autoscaling)** : 根据流量和资源使用情况/指标自动扩缩容您的服务. 
- 📖 **[KV Cache Offloading](https://kserve.github.io/website/docs/model-serving/generative-inference/kvcache-offloading)** - Learn how to offload key-value caches to external storage for improved performance and reduced latency.  
  📖 **[键值缓存卸载](https://kserve.github.io/website/docs/model-serving/generative-inference/kvcache-offloading)** - 了解如何将键值缓存卸载到外部存储, 以提高性能并降低延迟. 
- 📖 **[Model Caching](https://kserve.github.io/website/docs/model-serving/generative-inference/modelcache/localmodel)** - Learn how to cache models for faster startup time.  
  📖 **[模型缓存](https://kserve.github.io/website/docs/model-serving/generative-inference/modelcache/localmodel)** - 了解如何缓存模型以加快启动速度. 
- 📖 **[Token Rate Limiting](https://kserve.github.io/website/docs/model-serving/generative-inference/ai-gateway/envoy-ai-gateway)** - Rate limit users based on token usage.  
  📖 **[代币速率限制](https://kserve.github.io/website/docs/model-serving/generative-inference/ai-gateway/envoy-ai-gateway)** - 根据代币使用情况限制用户速率. 

[Edit this page](https://github.com/kserve/website/tree/main/versioned_docs/version-0.17/getting-started/genai-first-isvc.md)

[

Previous  以前的

Quickstart Guide  快速入门指南

](https://kserve.github.io/website/docs/getting-started/quickstart-guide)[

Next  下一个

Deploy Your First LLM InferenceService  
部署您的第一个 LLM 推理服务

](https://kserve.github.io/website/docs/getting-started/genai-first-llmisvc)