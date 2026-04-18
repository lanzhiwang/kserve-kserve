# Deploy Your First Predictive Inference Service

部署您的第一个预测推理服务

In this tutorial, you will deploy an InferenceService with a predictor that loads a scikit-learn model trained with the [iris](https://archive.ics.uci.edu/ml/datasets/iris) dataset. This dataset has three output classes: Iris Setosa, Iris Versicolour, and Iris Virginica.  
在本教程中, 您将部署一个推理服务, 其中包含一个预测器, 该预测器加载一个使用[鸢尾花](https://archive.ics.uci.edu/ml/datasets/iris)数据集训练的 scikit-learn 模型. 该数据集包含三个输出类别: 山鸢尾 (Iris Setosa)、杂色鸢尾 (Iris Versicolour) 和维吉尼亚鸢尾 (Iris Virginica). 

You will then send an inference request to your deployed model to get a prediction for the class of iris plant your request corresponds to.  
然后, 您将向已部署的模型发送推理请求, 以获取与您的请求对应的鸢尾花植物类别的预测结果. 

Since your model is being deployed as an InferenceService, not a raw Kubernetes Service, you just need to provide the storage location of the model and it gets some **super powers out of the box** 🚀.  
由于您的模型是作为推理服务部署的, 而不是作为原始 Kubernetes 服务部署的, 因此您只需提供模型的存储位置, 它就能**开箱即用, 获得一些强大的功能** 🚀. 

### Prerequisites  先决条件

Before you begin, ensure you have followed the [KServe Quickstart Guide](https://kserve.github.io/website/docs/getting-started/quickstart-guide) to set up KServe in your Kubernetes cluster. This guide assumes you have a working KServe installation and a Kubernetes cluster ready for deployment.  
开始之前, 请确保您已按照 [KServe 快速入门指南](https://kserve.github.io/website/docs/getting-started/quickstart-guide)在 Kubernetes 集群中配置好 KServe. 本指南假设您已成功安装 KServe 并准备好部署所需的 Kubernetes 集群. 

### 1. Create a namespace  1. 创建命名空间

First, create a namespace to use for deploying KServe resources:  
首先, 创建一个用于部署 KServe 资源的命名空间: 

```
kubectl create namespace kserve-test
```

### 2. Create an `InferenceService`

2. 创建 `InferenceService`

Create an InferenceService to deploy the Iris model. This model will be served using KServe's Scikit-learn runtime for optimized performance.  
创建一个推理服务来部署 Iris 模型. 该模型将使用 KServe 的 Scikit-learn 运行时进行服务, 以优化性能. 

::: warning Do not deploy `InferenceServices` in control plane namespaces (i.e. namespaces with `control-plane` label). The webhook is configured in a way to skip these namespaces to avoid any privilege escalations. Deploying InferenceServices to these namespaces will result in the storage initializer not being injected into the pod, causing the pod to fail with the error `No such file or directory: '/mnt/models'`. :::  
警告: 请勿在控制平面命名空间(即带有 `control-plane` 标签的命名空间)中部署 `InferenceServices` 已配置为跳过这些命名空间, 以避免任何权限提升. 将 InferenceServices 部署到这些命名空间会导致存储初始化程序无法注入到 Pod 中, 从而导致 Pod 失败并出现错误 `No such file or directory: '/mnt/models'`. 

- Apply from stdin  从标准输入应用
- Yaml

```
kubectl apply -n kserve-test -f - <<EOFapiVersion: "serving.kserve.io/v1beta1"kind: "InferenceService"metadata:  name: "sklearn-iris"  namespace: kserve-testspec:  predictor:    model:      modelFormat:        name: sklearn      storageUri: "gs://kfserving-examples/models/sklearn/1.0/model"      resources:        requests:          cpu: "100m"          memory: "512Mi"        limits:          cpu: "1"          memory: "1Gi"EOF
```

### 3. Check `InferenceService` status

3. 检查 `InferenceService` 状态

```
kubectl get inferenceservices sklearn-iris -n kserve-test
```

Expected Output  预期输出

```
NAME           URL                                                 READY   PREV   LATEST   PREVROLLEDOUTREVISION   LATESTREADYREVISION                    AGEsklearn-iris   http://sklearn-iris.kserve-test.example.com         True           100                              sklearn-iris-predictor-default-47q2g   7d23h
```

Knative serverless Custom Domain  
KNATIVE 无服务器自定义域名

If your DNS contains example.com please consult your admin for configuring DNS or using [custom domain](https://knative.dev/docs/serving/using-a-custom-domain).  
如果您的 DNS 中包含 example.com, 请咨询您的管理员以配置 DNS 或使用[自定义域名](https://knative.dev/docs/serving/using-a-custom-domain). 

### 4. Determine the ingress IP and ports

4. 确定入口 IP 地址和端口

Execute the following command to determine if your kubernetes cluster is running in an environment that supports external load balancers  
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

First, prepare your inference input request inside a file:  
首先, 请在文件中准备好您的推理输入请求: 

```
cat <<EOF > "./iris-input.json"{  "instances": [    [6.8,  2.8,  4.8,  1.4],    [6.0,  3.4,  4.5,  1.6]  ]}EOF
```

Depending on your setup, use one of the following commands to curl the `InferenceService`:  
根据您的设置, 使用以下命令之一来 curl `InferenceService` : 

- Real DNS  真实域名系统
- Magic DNS  魔法 DNS
- From Ingress gateway with HOST Header  来自带有 HOST 标头的 Ingress 网关
- From local cluster gateway  从本地集群网关
- Inference Python Client  Python 客户端推理

If you have configured the DNS, you can directly curl the `InferenceService` with the URL obtained from the status print.  
如果您已配置 DNS, 则可以直接使用从状态打印中获取的 URL 通过 curl 命令访问 `InferenceService`. 

```
curl -v -H "Content-Type: application/json" http://sklearn-iris.kserve-test.${CUSTOM_DOMAIN}/v1/models/sklearn-iris:predict -d @./iris-input.json
```

You should see two predictions returned (i.e. `{"predictions": [1, 1]}`). Both sets of data points sent for inference correspond to the flower with index `1`. In this case, the model predicts that both flowers are "Iris Versicolour".  
你应该看到返回两个预测结果(即 `{"predictions": [1, 1]}` ). 用于推理的两组数据点都对应于索引为 `1` 花朵. 在本例中, 模型预测这两朵花都是“变色鸢尾”. 

### 6. Run performance test (optional)

6. 运行性能测试(可选)

If you want to load test the deployed model, try deploying the following Kubernetes Job to drive load to the model:  
如果要对已部署的模型进行负载测试, 请尝试部署以下 Kubernetes 作业来驱动模型负载: 

```
# use kubectl create instead of apply because the job template is using generateName which doesn't work with kubectl applykubectl create -f https://raw.githubusercontent.com/kserve/kserve/release-<ActiveDocsVersion />/docs/samples/v1beta1/sklearn/v1/perf.yaml -n kserve-test
```

Execute the following command to view output:  
执行以下命令查看输出: 

```
kubectl logs load-test8b58n-rgfxr -n kserve-test
```

Expected Output  预期输出

```
Requests      [total, rate, throughput]         30000, 500.02, 499.99Duration      [total, attack, wait]             1m0s, 59.998s, 3.336msLatencies     [min, mean, 50, 90, 95, 99, max]  1.743ms, 2.748ms, 2.494ms, 3.363ms, 4.091ms, 7.749ms, 46.354msBytes In      [total, mean]                     690000, 23.00Bytes Out     [total, mean]                     2460000, 82.00Success       [ratio]                           100.00%Status Codes  [code:count]                      200:30000Error Set:
```

## Next Steps  后续步骤

Now that you have successfully deployed your first Predictive InferenceService, you can explore more advanced features of KServe, such as:  
现在您已成功部署了第一个预测推理服务, 接下来可以探索 KServe 的更多高级功能, 例如: 

- 📖 **[GenAI InferenceService](https://kserve.github.io/website/docs/getting-started/genai-first-isvc)** - Deploy your first Generative AI InferenceService  
  📖 **[GenAI 推理服务](https://kserve.github.io/website/docs/getting-started/genai-first-isvc)** - 部署您的第一个生成式 AI 推理服务
- 📖 **[KServe Concepts](https://kserve.github.io/website/docs/concepts)** - Learn about the core concepts of KServe.  
  📖 **[KServe 概念](https://kserve.github.io/website/docs/concepts)** - 了解 KServe 的核心概念. 
- 📖 **[Supported Frameworks](https://kserve.github.io/website/docs/model-serving/predictive-inference/frameworks/overview)** - Explore Supported Frameworks.  
  📖 **[支持的框架](https://kserve.github.io/website/docs/model-serving/predictive-inference/frameworks/overview)** - 探索支持的框架. 
- 📖 **[Batch InferenceService](https://kserve.github.io/website/docs/model-serving/predictive-inference/batcher)** - Deploy your first Batch InferenceService.  
  📖 **[批量推理服务](https://kserve.github.io/website/docs/model-serving/predictive-inference/batcher)** - 部署您的第一个批量推理服务. 
- 📖 **[Canary Deployments](https://kserve.github.io/website/docs/model-serving/predictive-inference/rollout-strategies/canary-example)**: Gradually roll out new model versions to test their performance before full deployment. 
  📖 **[金丝雀部署](https://kserve.github.io/website/docs/model-serving/predictive-inference/rollout-strategies/canary-example)** : 在全面部署之前逐步推出新模型版本以测试其性能. 

[Edit this page](https://github.com/kserve/website/tree/main/versioned_docs/version-0.17/getting-started/predictive-first-isvc.md)

[

Previous  以前的

Deploy Your First LLM InferenceService  
部署您的第一个 LLM 推理服务

](https://kserve.github.io/website/docs/getting-started/genai-first-llmisvc)[

Next  下一个

Swagger UI

](https://kserve.github.io/website/docs/getting-started/swagger-ui)