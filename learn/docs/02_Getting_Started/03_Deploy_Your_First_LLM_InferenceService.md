# Deploy Your First LLM InferenceService

部署您的第一个 LLM 推理服务

Quick guide to deploy your first LLMInferenceService using a simple CPU-based example.  
快速指南: 使用简单的基于 CPU 的示例部署您的第一个 LLMInferenceService. 

## Prerequisites  先决条件

Before starting, ensure you have:  
开始之前, 请确保您已准备好: 

- **LLMInferenceService installed**: Follow the [Quickstart Guide](https://kserve.github.io/website/docs/getting-started/quickstart-guide) to install LLMInferenceService and its dependencies  
  **LLMInferenceService 已安装** : 请按照[快速入门指南](https://kserve.github.io/website/docs/getting-started/quickstart-guide)安装 LLMInferenceService 及其依赖项
- Kubernetes cluster with `kubectl` access  
  具有 `kubectl` 访问权限的 Kubernetes 集群

---

## Quick Start: Single-Node CPU Deployment

快速入门: 单节点 CPU 部署

### Step 1: Create a Namespace

步骤 1: 创建命名空间

```
kubectl create namespace llm-demo
```

### Step 2: Deploy LLM Inference Service

步骤 2: 部署 LLM 推理服务

Deploy Facebook OPT-125M model (small model for CPU testing):  
部署 Facebook OPT-125M 模型(用于 CPU 测试的小型模型): 

```
kubectl apply -n llm-demo -f - <<EOFapiVersion: serving.kserve.io/v1alpha1kind: LLMInferenceServicemetadata:  name: facebook-opt-125m-singlespec:  model:    uri: hf://facebook/opt-125m    name: facebook/opt-125m  replicas: 1  template:    containers:      - name: main        image: quay.io/pierdipi/vllm-cpu:latest        securityContext:          runAsNonRoot: false  # Image requires root        env:          - name: VLLM_LOGGING_LEVEL            value: DEBUG        resources:          limits:            cpu: '1'            memory: 10Gi          requests:            cpu: '100m'            memory: 8Gi        livenessProbe:          initialDelaySeconds: 30          periodSeconds: 30          timeoutSeconds: 30          failureThreshold: 5  router:    gateway: {}    route: {}    scheduler: {}EOF
```

**What this creates**:  
**这将产生以下结果** : 

- **Deployment**: 1 pod running vLLM CPU with Facebook OPT-125M model  
  **部署** : 1 个运行 vLLM CPU 的 pod, 采用 Facebook OPT-125M 型号
- **Service**: Internal service for the deployment  
  **服务** : 部署的内部服务
- **Gateway**: Entry point for external traffic  
  **网关** : 外部流量的入口点
- **HTTPRoute**: Routes traffic to the scheduler  
  **HTTPRoute** : 将流量路由到调度程序
- **Scheduler Resources**: InferencePool, InferenceModel, and EPP (Endpoint Picker Pod)  
  **调度器资源** : 推理池、推理模型和 EPP(端点选择器 Pod)

### Step 3: Verify Deployment

步骤 3: 验证部署

Check the deployment status:  
检查部署状态: 

```
# Check LLMInferenceService statuskubectl get llminferenceservice facebook-opt-125m-single -n llm-demo# Check all created resourceskubectl get deployment,service,gateway,httproute,inferencepool -n llm-demo# Watch pods until Runningkubectl get pods -n llm-demo -w
```

Wait until the pod shows `Running` status and all containers are ready (this may take a few minutes for model download).  
等待 pod 显示 `Running` 状态且所有容器都准备就绪(模型下载可能需要几分钟时间). 

Expected Output  预期输出

```
NAME                                          URL                                               READY   AGEllminferenceservice.serving.kserve.io/facebook-opt-125m-single   http://facebook-opt-125m-single-kserve-gateway...   True    5m
```

### Step 4: Test Inference  步骤 4: 检验推断

Once the service is ready, test it with a completion request:  
服务准备就绪后, 使用完成请求对其进行测试: 

```
# Get the Gateway URL if you have external LB not KIND cloud-provider# GATEWAY_URL=$(kubectl get llminferenceservice facebook-opt-125m-single -n llm-demo -o jsonpath='{.status.url}')kubectl port-forward $(oc get svc -n envoy-gateway-system -l serving.kserve.io/gateway=kserve-ingress-gateway --no-headers -o name)  -n envoy-gateway-system 8001:80 &# Send a completion requestcurl -sS -X POST http://localhost:8001/llm-demo/facebook-opt-125m-single/v1/completions   \    -H 'accept: application/json'   \    -H 'Content-Type: application/json'    \    -d '{        "model": "facebook/opt-125m",        "prompt":"Who are you?"      }'
```

**Expected response**:  
**预期回复** : 

```
{  "id": "cmpl-f0601f1b-66cc-4f0c-bd0c-cc93c8afd9ec",  "object": "text_completion",  "created": 1751477229,  "model": "facebook/opt-125m",  "choices": [    {      "index": 0,      "text": " big place and I'd imagine it will stay that way. Until the US rel",      "logprobs": null,      "finish_reason": "length",      "stop_reason": null,      "prompt_logprobs": null    }  ],  "usage": {    "prompt_tokens": 5,    "total_tokens": 21,    "completion_tokens": 16,    "prompt_tokens_details": null  },  "kv_transfer_params": null}
```

### Step 5: Clean Up  第五步: 清理

When you're done testing, remove all resources:  
测试完成后, 请移除所有资源: 

```
# Delete the LLMInferenceService (automatically deletes all child resources)kubectl delete llminferenceservice facebook-opt-125m-single -n llm-demo# Delete the namespacekubectl delete namespace llm-demo
```

---

## Next Steps  后续步骤

**Learn more about LLMInferenceService**:  
**了解更多关于 LLM 推理服务的信息** : 

- 📖 [LLMInferenceService Overview](https://kserve.github.io/website/docs/model-serving/generative-inference/llmisvc/llmisvc-overview) - Understand LLMInferenceService  
  📖 [LLM 推理服务概述](https://kserve.github.io/website/docs/model-serving/generative-inference/llmisvc/llmisvc-overview) - 了解 LLM 推理服务
- 📖 [LLMInferenceService Configuration](https://kserve.github.io/website/docs/model-serving/generative-inference/llmisvc/llmisvc-configuration) - Explore configuration options  
  📖 [LLMInferenceService 配置](https://kserve.github.io/website/docs/model-serving/generative-inference/llmisvc/llmisvc-configuration) - 探索配置选项
- 📖 [Control Plane - LLMInferenceService](https://kserve.github.io/website/docs/concepts/architecture/control-plane-llmisvc) - Understand architecture  
  📖 [控制平面 - LLM 推理服务](https://kserve.github.io/website/docs/concepts/architecture/control-plane-llmisvc) - 了解架构

**Explore advanced deployment patterns**:  
**探索高级部署模式** : 

- 📖 [Single-Node GPU Example](https://github.com/kserve/kserve/tree/master/docs/samples/llmisvc/single-node-gpu) - GPU-accelerated inference  
  📖 [单节点 GPU 示例](https://github.com/kserve/kserve/tree/master/docs/samples/llmisvc/single-node-gpu) - GPU 加速推理
- 📖 [Multi-Node Deployment (Data Parallelism)](https://github.com/kserve/kserve/tree/master/docs/samples/llmisvc/dp-ep) - Scale across multiple nodes  
  📖 [多节点部署(数据并行)](https://github.com/kserve/kserve/tree/master/docs/samples/llmisvc/dp-ep) - 跨多个节点扩展
- 📖 [All Samples](https://github.com/kserve/kserve/tree/master/docs/samples/llmisvc) - Browse all example configurations  
  📖 [所有示例](https://github.com/kserve/kserve/tree/master/docs/samples/llmisvc) - 浏览所有示例配置

[Edit this page](https://github.com/kserve/website/tree/main/versioned_docs/version-0.17/getting-started/genai-first-llmisvc.md)

[

Previous  以前的

Deploy Your First GenAI Service  
部署您的第一代人工智能服务

](https://kserve.github.io/website/docs/getting-started/genai-first-isvc)[](https://kserve.github.io/website/docs/getting-started/predictive-first-isvc)