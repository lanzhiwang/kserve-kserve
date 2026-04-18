# Swagger UI

KServe ModelServer is built on top of [FastAPI](https://github.com/tiangolo/fastapi), which brings out-of-box support for [OpenAPI specification](https://www.openapis.org/) and [Swagger UI](https://swagger.io/tools/swagger-ui/).  
KServe ModelServer 构建于 [FastAPI](https://github.com/tiangolo/fastapi) 之上, 它为 [OpenAPI 规范](https://www.openapis.org/)和 [Swagger UI](https://swagger.io/tools/swagger-ui/) 提供了开箱即用的支持. 

Swagger UI allows visualizing and interacting with the KServe InferenceService API directly **in the browser**, making it easy for exploring the endpoints and validating the outputs without using any command-line tool.  
Swagger UI 允许直接**在浏览器中**可视化和与 KServe InferenceService API 进行交互, 从而可以轻松探索端点并验证输出, 而无需使用任何命令行工具. 

![KServe ModelServer Swagger UI](https://kserve.github.io/website/assets/images/kserve-swagger-ui-06d59e0c3bd81dfe35cb6ca2a05f896a.png)

## Enable Swagger UI  启用 Swagger UI

warning  警告

Be careful when enabling this for your **production** InferenceService deployments since the endpoint does not require authentication at this time.  
在**生产环境的** InferenceService 部署中启用此功能时请务必小心, 因为该端点目前不需要身份验证. 

Currently, `POST` request only work for `v2` endpoints in the UI.  
目前,  `POST` 请求仅适用于 UI 中的 `v2` 端点. 

To enable, simply add an extra argument to the InferenceService YAML example from [First Inference](https://kserve.github.io/website/docs/getting-started/predictive-first-isvc) chapter:  
要启用此功能, 只需在 [“首次推理”](https://kserve.github.io/website/docs/getting-started/predictive-first-isvc) 章节中的 InferenceService YAML 示例中添加一个额外的参数即可: 

```
kubectl apply -n kserve-test -f - <<EOFapiVersion: "serving.kserve.io/v1beta1"kind: "InferenceService"metadata:  name: "sklearn-iris"spec:  predictor:    model:      args: ["--enable_docs_url=True"]      modelFormat:        name: sklearn      runtime: kserve-sklearnserver      storageUri: "gs://kfserving-examples/models/sklearn/1.0/model"EOF
```

After the InferenceService becomes ready the Swagger UI will be served at **`/docs`**. In our example above, the Swagger UI will be available at `http://sklearn-iris.kserve-test.example.com/docs`.  
InferenceService 准备就绪后, Swagger UI 将在 **`/docs`** 上提供服务. 在上面的示例中, Swagger UI 将在 `http://sklearn-iris.kserve-test.example.com/docs` 上可用. 

!!! note The Swagger UI may not be exposed or exposed with a different endpoint on other serving runtimes. For example, the MLServer runtime exposes the Swagger UI at `/v2/docs` endpoint. This example is only applicable to the KServe provided runtimes and runtimes that extend the KServe runtime SDK.  
!!! 注意: Swagger UI 可能不会在其他服务运行时上公开, 或者会通过不同的端点公开. 例如, MLServer 运行时通过 `/v2/docs` 端点公开 Swagger UI. 此示例仅适用于 KServe 提供的运行时以及扩展了 KServe 运行时 SDK 的运行时. 

## Interact with InferenceService

与推理服务交互

Click one of the V2 endpoints like `/v2`, it will expand and display the description and response from this API endpoint:  
点击 V2 端点之一, 例如 `/v2` , 它将展开并显示此 API 端点的描述和响应: 

![V2 Metadata](https://kserve.github.io/website/assets/images/v2-metadata-1acc9290b5e6e600a3d7c450a5ea4799.png)

Now, when you click "Try it out" and then "Execute", Swagger UI will send a `GET` request to the `/v2` endpoint. The server response body and headers will be displayed at the bottom:  
现在, 当您点击“试用”然后点击“执行”时, Swagger UI 将向 `/v2` 端点发送一个 `GET` 请求. 服务器响应正文和标头将显示在底部: 

![V2 Metadata](https://kserve.github.io/website/assets/images/v2-metadata-try-out-26058f261a6e06b07fd61d864f940658.png)

Similarly, we can use Swagger UI to send request to check the model metadata and make prediction using the `/v2/models/{model_name}/infer` endpoint.  
类似地, 我们可以使用 Swagger UI 发送请求来检查模型元数据, 并使用 `/v2/models/{model_name}/infer` 端点进行预测. 

For more reference, please check out [Model Serving Data Plane](https://kserve.github.io/website/docs/concepts/architecture/data-plane) for detailed documentation on the Inference Protocol.  
如需更多参考信息, 请查看[模型服务数据平面](https://kserve.github.io/website/docs/concepts/architecture/data-plane) , 了解有关推理协议的详细文档. 

[Edit this page](https://github.com/kserve/website/tree/main/versioned_docs/version-0.17/getting-started/swagger-ui.md)

[

Previous  以前的

Deploy Your First Predictive AI Service  
部署您的第一个预测性人工智能服务

](https://kserve.github.io/website/docs/getting-started/predictive-first-isvc)[](https://kserve.github.io/website/docs/concepts)