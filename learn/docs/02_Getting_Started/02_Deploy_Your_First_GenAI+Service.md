# Deploy Your First GenAI Service

In this tutorial, you will deploy a Large Language Model (LLM) using KServe's InferenceService to create a powerful generative AI service. We'll use the Qwen model, a state-of-the-art language model developed by Alibaba, capable of understanding and generating human-like text across multiple languages.
在本教程中, 您将使用 KServe 的 InferenceService 部署大型语言模型 (LLM), 从而创建一个强大的生成式 AI 服务. 我们将使用 Qwen 模型, 这是一款由阿里巴巴开发的先进语言模型, 能够理解并生成多种语言的类人文本.

You will learn how to deploy the model and interact with it using OpenAI-compatible APIs, making it easy to integrate with existing applications and tools that support the OpenAI standard.
您将学习如何部署模型并使用与 OpenAI 兼容的 API 与之交互, 从而轻松地将其集成到支持 OpenAI 标准的现有应用程序和工具中.

Since your LLM is deployed as an InferenceService rather than a basic Kubernetes deployment, you automatically get enterprise-grade features like **autoscaling**, **load balancing**, **canary deployments**, and **GPU acceleration** out of the box 🚀.
由于您的 LLM 是作为推理服务部署的, 而不是作为基本的 Kubernetes 部署, 因此您可以自动获得企业级功能, 例如自动扩缩容、负载均衡、金丝雀部署和 GPU 加速 🚀.

### Prerequisites  先决条件

Before you begin, ensure you have followed the [KServe Quickstart Guide](https://kserve.github.io/website/docs/getting-started/quickstart-guide) to set up KServe in your Kubernetes cluster. This guide assumes you have a working KServe installation and a Kubernetes cluster ready for deployment.
开始之前, 请确保您已按照 KServe 快速入门指南在 Kubernetes 集群中配置好 KServe. 本指南假设您已成功安装 KServe 并准备好部署所需的 Kubernetes 集群.

> tip
> KServe recommends Standard Deployment for Generative AI use cases.
> KServe 建议对生成式人工智能用例采用标准部署.
>

### 1. Create a namespace

First, create a namespace to use for deploying KServe resources:

```bash
kubectl create namespace kserve-test
```

### 2. Create an `InferenceService`

Create an InferenceService to deploy the Qwen LLM model. This model will be served using KServe's Hugging Face runtime with vLLM backend for optimized performance.
创建 InferenceService 以部署 Qwen LLM 模型. 该模型将使用 KServe 的 Hugging Face 运行时和 vLLM 后端进行服务, 以优化性能.

> warning
> Do not deploy `InferenceServices` in control plane namespaces (i.e. namespaces with `control-plane` label). The webhook is configured in a way to skip these namespaces to avoid any privilege escalations. Deploying InferenceServices to these namespaces will result in the storage initializer not being injected into the pod, causing the pod to fail with the error `No such file or directory: '/mnt/models'`.
> 请勿在控制平面命名空间(即带有 `control-plane` 标签的命名空间)中部署 `InferenceServices` 配置为跳过这些命名空间, 以避免任何权限提升. 将 InferenceServices 部署到这些命名空间会导致存储初始化程序无法注入到 pod 中, 从而导致 pod 失败并出现错误 `No such file or directory: '/mnt/models'`.
>

- Apply from stdin

```bash
kubectl apply -n kserve-test -f - <<EOF
apiVersion: "serving.kserve.io/v1beta1"
kind: "InferenceService"
metadata:
  name: "qwen-llm"
  namespace: kserve-test
spec:
  predictor:
    model:
      modelFormat:
        name: huggingface
      args:
        - --model_name=qwen
      storageUri: "hf://Qwen/Qwen2.5-0.5B-Instruct"
      resources:
        limits:
          cpu: "2"
          memory: 6Gi
          nvidia.com/gpu: "1"
        requests:
          cpu: "1"
          memory: 4Gi
          nvidia.com/gpu: "1"
EOF
```

- Yaml

```yaml
apiVersion: "serving.kserve.io/v1beta1"
kind: "InferenceService"
metadata:
  name: "qwen-llm"
  namespace: kserve-test
spec:
  predictor:
    model:
      modelFormat:
        name: huggingface
      args:
        - --model_name=qwen
      storageUri: "hf://Qwen/Qwen2.5-0.5B-Instruct"
      resources:
        limits:
          cpu: "2"
          memory: 6Gi
          nvidia.com/gpu: "1"
        requests:
          cpu: "1"
          memory: 4Gi
          nvidia.com/gpu: "1"
```

> Using Hugging Face Token
> If you need to authenticate with Hugging Face, first create a secret:
> 如果您需要使用 Hugging Face 进行身份验证, 请先创建一个密钥:
>
> ```bash
> kubectl create secret generic hf-secret --from-literal=HF_TOKEN=your_hf_token_here -n kserve-test
> ```
>
> Then create a `clusterstoragecontainer` resource with the secret reference:
>
> ```yaml
> apiVersion: "serving.kserve.io/v1alpha1"
> kind: ClusterStorageContainer
> metadata:
>   name: hf-hub
> spec:
>   container:
>     name: storage-initializer
>     image: kserve/storage-initializer:latest
>     env:
>     - name: HF_TOKEN
>       valueFrom:
>         secretKeyRef:
>           name: hf-secret
>           key: HF_TOKEN
>           optional: false
>     resources:
>       requests:
>         memory: 2Gi
>         cpu: "1"
>       limits:
>         memory: 4Gi
>         cpu: "1"
>   supportedUriFormats:
>     - prefix: hf://
> ```
>

### 3. Check `InferenceService` status.

```bash
kubectl get inferenceservices qwen-llm -n kserve-test
NAME       URL                                             READY   PREV   LATEST   PREVROLLEDOUTREVISION   LATESTREADYREVISION                AGE
qwen-llm   http://qwen-llm.kserve-test.example.com         True           100                              qwen-llm-predictor-default-47q2g   7d23h
```

If your DNS contains example.com please consult your admin for configuring DNS or using [custom domain](https://knative.dev/docs/serving/using-a-custom-domain).
如果您的 DNS 中包含 example.com, 请咨询您的管理员以配置 DNS 或使用[自定义域名](https://knative.dev/docs/serving/using-a-custom-domain).

### 4. Determine the ingress IP and ports

Execute the following command to determine if your Kubernetes cluster is running in an environment that supports external load balancers
执行以下命令以确定您的 Kubernetes 集群是否运行在支持外部负载均衡器的环境中.

```bash
kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)   AGE
istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121   ...       17h
```

- Load Balancer  负载均衡器

If the EXTERNAL-IP value is set, your environment has an external load balancer that you can use for the ingress gateway.
如果设置了 EXTERNAL-IP 值, 则您的环境中有一个外部负载均衡器, 您可以将其用作入口网关.

```bash
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
```

- Node Port  节点端口

If the EXTERNAL-IP value is none (or perpetually pending), your environment does not provide an external load balancer for the ingress gateway. In this case, you can access the gateway using the service’s node port.
如果 EXTERNAL-IP 值为 none(或始终处于挂起状态), 则表示您的环境未为入口网关提供外部负载均衡器. 在这种情况下, 您可以使用服务的节点端口访问网关.

```bash
# GKE
export INGRESS_HOST=worker-node-address
# Minikube
export INGRESS_HOST=$(minikube ip)
# Other environment(On Prem)
export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
```

- Port Forward

Alternatively you can do Port Forward for testing purposes.
或者, 您也可以进行 Port Forward 以进行测试.

```bash
INGRESS_GATEWAY_SERVICE=$(kubectl get svc --namespace istio-system --selector="app=istio-ingressgateway" --output jsonpath='{.items[0].metadata.name}')
kubectl port-forward --namespace istio-system svc/${INGRESS_GATEWAY_SERVICE} 8080:80
```

Open another terminal, and enter the following to perform inference:
打开另一个终端, 输入以下命令进行推理:

```bash
export INGRESS_HOST=localhost
export INGRESS_PORT=8080

SERVICE_HOSTNAME=$(kubectl get inferenceservice qwen-llm -n kserve-test -o jsonpath='{.status.url}' | cut -d "/" -f 3)
curl -v -H "Host: ${SERVICE_HOSTNAME}" -H "Content-Type: application/json" "http://${INGRESS_HOST}:${INGRESS_PORT}/openai/v1/chat/completions" -d @./chat-input.json
```

### 5. Perform inference

Create a JSON file named `chat-input.json` with the following content to send a chat completion request to the Qwen model:
创建一个名为 `chat-input.json` 的 JSON 文件, 内容如下, 用于向 Qwen 模型发送聊天完成请求:

```bash
cat <<EOF > "./chat-input.json"
{
  "model": "qwen",
  "messages": [
    {
      "role": "system",
      "content": "You are a helpful assistant that provides clear and concise answers."
    },
    {
      "role": "user",
      "content": "Write a short poem about artificial intelligence and machine learning."
    }
  ],
  "max_tokens": 150,
  "temperature": 0.7,
  "stream": false
}
EOF
```

Depending on your setup, use one of the following commands to curl the `InferenceService`:

- Real DNS

```bash
curl -v -H "Content-Type: application/json" http://qwen-llm.kserve-test.example.com/openai/v1/chat/completions -d @./chat-input.json
```

- Magic DNS

```bash
curl -v -H "Content-Type: application/json" http://qwen-llm.kserve-test.xip.io/openai/v1/chat/completions -d @./chat-input.json
```

- From Ingress gateway with HOST Header

```bash
SERVICE_HOSTNAME=$(kubectl get inferenceservice qwen-llm -n kserve-test -o jsonpath='{.status.url}' | cut -d "/" -f 3)
curl -v -H "Host: ${SERVICE_HOSTNAME}" -H "Content-Type: application/json" "http://${INGRESS_HOST}:${INGRESS_PORT}/openai/v1/chat/completions" -d @./chat-input.json
```

- From local cluster gateway

```bash
curl -v -H "Content-Type: application/json" http://qwen-llm.kserve-test/openai/v1/chat/completions -d @./chat-input.json
```

- OpenAI Python Client

```python
from openai import OpenAI
# Configure the client to point to your KServe endpoint
client = OpenAI(
    api_key="not-needed",  # KServe doesn't require API key authentication
    base_url="http://qwen-llm.kserve-test/openai/v1"  # Note the /openai prefix
)
# Send a chat completion request
response = client.chat.completions.create(
    model="qwen",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Write a short poem about artificial intelligence."}
    ],
    max_tokens=150,
    temperature=0.7
)
print(response.choices[0].message.content)
```

You should see a response similar to the following, which contains the generated text from the Qwen model:
您应该会看到类似以下内容的响应, 其中包含 Qwen 模型生成的文本:

```json
{
  "id": "cmpl-generated-id",
  "object": "chat.completion",
  "created": 1703123456,
  "model": "qwen",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Here's a poem about artificial intelligence and machine learning:\n\nSilicon minds awakening bright,\nThrough data streams and neural flight,\nPatterns learned from endless code,\nAI walks the digital road.\n\nMachine learning, wise and true,\nFinds the answers we pursue,\nIn the dance of ones and zeros,\nTechnology becomes our heroes."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 45,
    "completion_tokens": 67,
    "total_tokens": 112
  }
}
```

### 6. Clean up

To clean up the resources created in this tutorial, delete the InferenceService and the namespace:

```bash
kubectl delete inferenceservice qwen-llm -n kserve-test
kubectl delete namespace kserve-test
```

### 7. Next Steps

Now that you have successfully deployed a generative AI service using KServe, you can explore more advanced features such as:
现在您已使用 KServe 成功部署了生成式 AI 服务, 接下来您可以探索更多高级功能, 例如:

- 📖 **[KServe Concepts](https://kserve.github.io/website/docs/concepts)** - Learn about the core concepts of KServe.
- 📖 **[Supported Tasks](https://kserve.github.io/website/docs/model-serving/generative-inference/overview#supported-generative-tasks)** - Discover the various tasks that KServe can handle.
- 📖 **[Autoscaling](https://kserve.github.io/website/docs/model-serving/generative-inference/autoscaling)**: Automatically scale your service based on traffic and resource usage / metrics.
- 📖 **[KV Cache Offloading](https://kserve.github.io/website/docs/model-serving/generative-inference/kvcache-offloading)** - Learn how to offload key-value caches to external storage for improved performance and reduced latency.
- 📖 **[Model Caching](https://kserve.github.io/website/docs/model-serving/generative-inference/modelcache/localmodel)** - Learn how to cache models for faster startup time.
- 📖 **[Token Rate Limiting](https://kserve.github.io/website/docs/model-serving/generative-inference/ai-gateway/envoy-ai-gateway)** - Rate limit users based on token usage.
