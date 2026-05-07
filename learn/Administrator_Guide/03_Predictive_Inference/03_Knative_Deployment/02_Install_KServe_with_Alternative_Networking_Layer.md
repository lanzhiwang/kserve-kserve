# Deploy InferenceService with Alternative Networking Layer
使用备用网络层部署推理服务

* https://kserve.github.io/website/docs/0.16/admin-guide/serverless/kourier-networking

KServe creates the top level `Istio Virtual Service` for routing to `InferenceService` components based on the virtual host or path based routing. Now KServe provides an option for disabling the top level virtual service to allow configuring other networking layers Knative supports. For example, [Kourier](https://developers.redhat.com/blog/2020/06/30/kourier-a-lightweight-knative-serving-ingress) is an alternative networking layer and the following steps show how you can deploy KServe with `Kourier`.
KServe 会创建顶层 `Istio Virtual Service`, 用于根据虚拟主机或路径路由将流量路由到 `InferenceService` 组件. 现在, KServe 提供了一个选项, 可以禁用顶层虚拟服务, 从而允许配置 Knative 支持的其他网络层. 例如, [Kourier](https://developers.redhat.com/blog/2020/06/30/kourier-a-lightweight-knative-serving-ingress) 就是一个可选的网络层, 以下步骤展示了如何将 KServe 与 `Kourier` 集成部署.

## Install Kourier Networking Layer
安装 Kourier 网络层

Please refer to the [Knative Serverless Installation Guide](https://kserve.github.io/website/docs/0.16/admin-guide/serverless) and change the second step to install `Kourier` instead of `Istio`.
请参考 [Knative Serverless 安装指南](https://kserve.github.io/website/docs/0.16/admin-guide/serverless), 并将第二步更改为安装 `Kourier` 而不是 `Istio`.

1. Install the Kourier networking layer:
  安装 Kourier 网络层:

```bash
kubectl apply -f https://github.com/knative/net-kourier/releases/download/${KNATIVE_VERSION}/kourier.yaml
```

2. Configure Knative Serving to use Kourier:
  配置 Knative Serving 使用 Kourier:

```bash
kubectl patch configmap/config-network \
--namespace knative-serving \
--type merge \
--patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'
```

3. Verify Kourier installation:
  验证 Kourier 安装:

```bash
kubectl get pods -n knative-serving && kubectl get pods -n kourier-system
```

Expected Output

```bash
NAME                                      READY   STATUS    RESTARTS   AGE
activator-77db7d9dd7-kbrgr                1/1     Running   0          10m
autoscaler-67dbf79b95-htnp9               1/1     Running   0          10m
controller-684b6bc97f-ffm58               1/1     Running   0          10m
domain-mapping-6d99d99978-ktmrf           1/1     Running   0          10m
domainmapping-webhook-5f998498b6-sddnm    1/1     Running   0          10m
net-kourier-controller-68967d76dc-ncj2n   1/1     Running   0          10m
webhook-97bdc7b4d-nr7qf                   1/1     Running   0          10m
NAME                                      READY   STATUS    RESTARTS   AGE
3scale-kourier-gateway-54c49c8ff5-x8tgn   1/1     Running   0          10m
```

## Configure KServe with Kourier
配置 KServe 与 Kourier

To deploy KServe with Kourier, you need to disable the built-in Istio Virtual Service creation:
要使用 Kourier 部署 KServe, 需要禁用内置的 Istio 虚拟服务创建功能:

1. Edit the `inferenceservice-config` configmap to disable Istio top level virtual host:
  编辑 `inferenceservice-config` 配置映射以禁用 Istio 顶级虚拟主机:

```bash
kubectl edit configmap/inferenceservice-config --namespace kserve
# Add the flag `"disableIstioVirtualHost": true` under the ingress section
ingress : |- {
    "disableIstioVirtualHost": true
}
```

  Alternatively, you can use this patch command:
  或者, 您可以使用以下补丁命令:

```bash
kubectl patch configmap/inferenceservice-config -n kserve --type=strategic -p '{"data": {"ingress": "{ \"disableIstioVirtualHost\": true}"}}'
```

2. Restart the KServe Controller:
  重启 KServe 控制器:

```bash
kubectl rollout restart deployment kserve-controller-manager -n kserve
```

3. Watch the KServe controller pod to verify it restarts with the new configuration:
  观察 KServe 控制器 pod, 验证其是否使用新配置重启:

```bash
kubectl get pods -n kserve --watch
```

## Deploy InferenceService for Testing Kourier Gateway
部署推理服务以测试 Kourier 网关

### Create the InferenceService
创建推理服务

Create a file named `pmml.yaml` with the following content:
创建一个名为 `pmml.yaml` 的文件, 内容如下:

```yaml
apiVersion: "serving.kserve.io/v1beta1"
kind: "InferenceService"
metadata:
  name: "pmml-demo"
spec:
  predictor:
    model:
      modelFormat:
        name: pmml
      storageUri: "gs://kfserving-examples/models/pmml"
```

Deploy the InferenceService:
部署推理服务:

```bash
kubectl apply -f pmml.yaml
```

Expected Output

```bash
inferenceservice.serving.kserve.io/pmml-demo created
```

### Run a Prediction

Note that when setting `INGRESS_HOST` and `INGRESS_PORT` following the [determining the ingress IP and ports](https://kserve.github.io/website/docs/0.16/getting-started/predictive-first-isvc#4-determine-the-ingress-ip-and-ports) guide you need to replace `istio-ingressgateway` with `kourier-gateway`.
请注意, 按照[确定入口 IP 和端口](https://kserve.github.io/website/docs/0.16/getting-started/predictive-first-isvc#4-determine-the-ingress-ip-and-ports)指南设置 `INGRESS_HOST` 和 `INGRESS_PORT` 时, 需要将 `istio-ingressgateway` 替换为 `kourier-gateway`.

For example if you choose to do `Port Forward` for testing you need to select the `kourier-gateway` pod as following.
例如, 如果您选择进行 `Port Forward` 测试, 则需要按如下方式选择 `kourier-gateway` pod.

```bash
kubectl port-forward --namespace kourier-system \
$(kubectl get pod -n kourier-system -l "app=3scale-kourier-gateway" --output=jsonpath="{.items[0].metadata.name}") 8080:8080
export INGRESS_HOST=localhost
export INGRESS_PORT=8080
```

Create a file named `pmml-input.json` with the following content, under your current terminal path:
在当前终端路径下创建一个名为 `pmml-input.json` 的文件, 并添加以下内容:

```json
{
    "instances": [
        [
            5.1,
            3.5,
            1.4,
            0.2
        ]
    ]
}
```

Send a prediction request to the InferenceService and check the output:
向推理服务发送预测请求并检查输出:

```bash
MODEL_NAME=pmml-demo
INPUT_PATH=@./pmml-input.json
SERVICE_HOSTNAME=$(kubectl get inferenceservice pmml-demo -o jsonpath='{.status.url}' | cut -d "/" -f 3)
curl -v -H "Host: ${SERVICE_HOSTNAME}" -H "Content-Type: application/json" http://${INGRESS_HOST}:${INGRESS_PORT}/v1/models/$MODEL_NAME:predict -d $INPUT_PATH
```

Expected Output

```bash
* Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 8080 (#0)
> POST /v1/models/pmml-demo:predict HTTP/1.1
> Host: pmml-demo-predictor-default.default.example.com
> User-Agent: curl/7.58.0
> Accept: */*
> Content-Length: 45
> Content-Type: application/x-www-form-urlencoded
>
* upload completely sent off: 45 out of 45 bytes
< HTTP/1.1 200 OK
< content-length: 144
< content-type: application/json; charset=UTF-8
< date: Wed, 14 Sep 2022 13:30:09 GMT
< server: envoy
< x-envoy-upstream-service-time: 58
<
* Connection #0 to host localhost left intact
{"predictions": [{"Species": "setosa", "Probability_setosa": 1.0, "Probability_versicolor": 0.0, "Probability_virginica": 0.0, "Node_Id": "2"}]}
```

## Benefits of Using Kourier

Kourier offers several benefits as an alternative networking layer for KServe:
Kourier 作为 KServe 的替代网络层, 具有以下几个优点:

- Lightweight and focused on Knative use cases
  轻量级且专注于 Knative 用例

- Simpler architecture compared to Istio
  与 Istio 相比, 架构更简单

- Lower resource usage
  降低资源利用率

- Faster startup time
  启动速度更快

- Easier to configure and manage
  更易于配置和管理

However, it lacks some of the advanced traffic management features of Istio, so choose the networking layer that best fits your requirements.
但是, 它缺少 Istio 的一些高级流量管理功能, 因此请选择最符合您需求的网络层.
