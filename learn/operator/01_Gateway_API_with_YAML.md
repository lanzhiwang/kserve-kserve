# Gateway API with YAML

1. Install KServe: `--server-side` option is required as the InferenceService CRD is large.

```bash
kubectl apply --server-side -f https://github.com/kserve/kserve/releases/download/v0.16.0/kserve.yaml

Namespace
  kserve

CustomResourceDefinition
  clusterservingruntimes.serving.kserve.io
  clusterstoragecontainers.serving.kserve.io
  inferencegraphs.serving.kserve.io
  inferencemodels.inference.networking.x-k8s.io
  inferencepools.inference.networking.x-k8s.io
  inferenceservices.serving.kserve.io
  llminferenceserviceconfigs.serving.kserve.io
  llminferenceservices.serving.kserve.io
  localmodelcaches.serving.kserve.io
  localmodelnodegroups.serving.kserve.io
  localmodelnodes.serving.kserve.io
  servingruntimes.serving.kserve.io
  trainedmodels.serving.kserve.io

ServiceAccount
  kserve-controller-manager
  kserve-localmodel-controller-manager
  kserve-localmodelnode-agent
  llmisvc-controller-manager

Role
  kserve-leader-election-role
  llmisvc-leader-election-role

ClusterRole
  kserve-localmodel-manager-role
  kserve-localmodelnode-agent-role
  kserve-manager-role
  kserve-proxy-role
  llmisvc-manager-role

RoleBinding
  kserve-leader-election-rolebinding
  llmisvc-leader-election-rolebinding

ClusterRoleBinding
  kserve-localmodel-manager-rolebinding
  kserve-localmodelnode-agent-rolebinding
  kserve-manager-rolebinding
  kserve-proxy-rolebinding
  llmisvc-manager-rolebinding

ConfigMap
  inferenceservice-config

Secret
  kserve-webhook-server-secret

Service
  kserve-controller-manager-metrics-service
  kserve-controller-manager-service
  kserve-webhook-server-service
  llmisvc-controller-manager-service
  llmisvc-webhook-server-service

Deployment
  kserve-controller-manager
  kserve-localmodel-controller-manager
  llmisvc-controller-manager

DaemonSet
  kserve-localmodelnode-agent

Certificate
  llmisvc-serving-cert
  serving-cert

Issuer
  selfsigned-issuer

LLMInferenceServiceConfig
  kserve-config-llm-decode-template
  kserve-config-llm-decode-worker-data-parallel
  kserve-config-llm-prefill-template
  kserve-config-llm-prefill-worker-data-parallel
  kserve-config-llm-router-route
  kserve-config-llm-scheduler
  kserve-config-llm-template
  kserve-config-llm-worker-data-parallel

MutatingWebhookConfiguration
  inferenceservice.serving.kserve.io

ValidatingWebhookConfiguration
  clusterservingruntime.serving.kserve.io
  inferencegraph.serving.kserve.io
  inferenceservice.serving.kserve.io
  llminferenceservice.serving.kserve.io
  llminferenceserviceconfig.serving.kserve.io
  localmodelcache.serving.kserve.io
  servingruntime.serving.kserve.io
  trainedmodel.serving.kserve.io

```

2. Install KServe default serving runtimes:

```bash
kubectl apply --server-side -f https://github.com/kserve/kserve/releases/download/v0.16.0/kserve-cluster-resources.yaml

ClusterServingRuntime
  kserve-huggingfaceserver
  kserve-huggingfaceserver-multinode
  kserve-lgbserver
  kserve-mlserver
  kserve-paddleserver
  kserve-pmmlserver
  kserve-sklearnserver
  kserve-tensorflow-serving
  kserve-torchserve
  kserve-tritonserver
  kserve-xgbserver

ClusterStorageContainer
  default

LLMInferenceServiceConfig

```

3. Change default deployment mode and ingress option

First in the ConfigMap `inferenceservice-config` modify the `defaultDeploymentMode` to `Standard`:

```bash
# {
#     "data": {
#         "deploy": {
#             "defaultDeploymentMode": "Standard"
#         }
#     }
# }
kubectl patch configmap/inferenceservice-config -n kserve --type=strategic -p '{"data":{"deploy":{"defaultDeploymentMode":"Standard"}}}'
```

Then enable Gateway API and configure the Gateway:

```bash
# {
#     "data": {
#         "ingress": {
#             "enableGatewayApi": true,
#             "kserveIngressGateway": "kserve/kserve-ingress-gateway"
#         }
#     }
# }
kubectl patch configmap/inferenceservice-config -n kserve --type=strategic -p '{"data":{"ingress":{"enableGatewayApi":true,"kserveIngressGateway":"kserve/kserve-ingress-gateway"}}}'
```
