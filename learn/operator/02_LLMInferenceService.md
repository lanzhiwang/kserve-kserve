# LLMInferenceService Installation

```bash
kustomize build config/overlays/standalone/llmisvc > learn/operator/LLMInferenceService.yaml

Namespace
  kserve

CustomResourceDefinition
  clusterstoragecontainers.serving.kserve.io
  inferencemodelrewrites.inference.networking.x-k8s.io
  inferenceobjectives.inference.networking.x-k8s.io
  inferencepoolimports.inference.networking.x-k8s.io
  inferencepools.inference.networking.k8s.io
  inferencepools.inference.networking.x-k8s.io
  llminferenceserviceconfigs.serving.kserve.io
  llminferenceservices.serving.kserve.io

ServiceAccount
  llmisvc-controller-manager

Role
  llmisvc-leader-election-role

ClusterRole
  ClusterRole

RoleBinding
  llmisvc-leader-election-rolebinding

ClusterRoleBinding
  llmisvc-manager-rolebinding

ConfigMap
  inferenceservice-config

Service
  llmisvc-controller-manager-service
  llmisvc-webhook-server-service

Deployment
  llmisvc-controller-manager

apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: llmisvc-serving-cert
  namespace: kserve

apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: selfsigned-issuer
  namespace: kserve

ClusterStorageContainer
  default

ValidatingWebhookConfiguration
  llminferenceservice.serving.kserve.io
  llminferenceserviceconfig.serving.kserve.io


kustomize build config/llmisvcconfig > learn/operator/llmisvcconfig.yaml

LLMInferenceServiceConfig
  kserve-config-llm-decode-template
  kserve-config-llm-decode-worker-data-parallel
  kserve-config-llm-prefill-template
  kserve-config-llm-prefill-worker-data-parallel
  kserve-config-llm-router-route
  kserve-config-llm-scheduler
  kserve-config-llm-template
  kserve-config-llm-worker-data-parallel


```


## LLMInferenceService Dependencies

```bash
# Step 1: Install cert-manager (required by LWS)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.0/cert-manager.yaml

# Step 2: Install Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml

CustomResourceDefinition
  gatewayclasses.gateway.networking.k8s.io
  gateways.gateway.networking.k8s.io
  grpcroutes.gateway.networking.k8s.io
  httproutes.gateway.networking.k8s.io
  referencegrants.gateway.networking.k8s.io

# Step 3: Install GIE CRDs (BEFORE Gateway Provider!)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/releases/download/v0.3.0/install.yaml

CustomResourceDefinition
  inferencemodels.inference.networking.x-k8s.io
  inferencepools.inference.networking.x-k8s.io

# Step 4: Install Gateway Provider (Envoy Gateway example)
helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.2.4 -n envoy-gateway-system --create-namespace

# https://github.com/envoyproxy/gateway/tree/v1.2.4/charts/gateway-helm
cp ./learn/operator/envoyproxy/gateway/charts/gateway-helm/values.tmpl.yaml ./learn/operator/envoyproxy/gateway/charts/gateway-helm/values.yaml
helm install --dry-run=client --debug -n envoy-gateway-system --create-namespace --version v1.2.4 eg ./learn/operator/envoyproxy/gateway/charts/gateway-helm > learn/operator/gateway.yaml 2>&1

ServiceAccount
  eg-gateway-helm-certgen
  envoy-gateway

Role
  eg-gateway-helm-certgen
  eg-gateway-helm-infra-manager
  eg-gateway-helm-leader-election-role

RoleBinding
  eg-gateway-helm-certgen
  eg-gateway-helm-infra-manager
  eg-gateway-helm-leader-election-rolebinding

ClusterRole
  eg-gateway-helm-envoy-gateway-role

ClusterRoleBinding
  eg-gateway-helm-envoy-gateway-rolebinding

Job
  eg-gateway-helm-certgen

ConfigMap
  envoy-gateway-config

Service
  envoy-gateway

Deployment
  envoy-gateway

# Step 5: Install LWS Operator (if using multi-node)
kubectl apply -f https://github.com/kubernetes-sigs/lws/releases/download/v0.6.2/lws-operator.yaml

Namespace
  lws-system

CustomResourceDefinition
  leaderworkersets.leaderworkerset.x-k8s.io

ServiceAccount
  lws-controller-manager

Role
  lws-leader-election-role

ClusterRole
  lws-manager-role
  lws-metrics-reader
  lws-proxy-role

RoleBinding
  lws-leader-election-rolebinding

ClusterRoleBinding
  lws-manager-rolebinding
  lws-metrics-reader-rolebinding
  lws-proxy-rolebinding

ConfigMap
  lws-manager-config

Secret
  lws-webhook-server-cert

Service
  lws-controller-manager-metrics-service
  lws-webhook-service

Deployment
  lws-controller-manager

MutatingWebhookConfiguration
  lws-mutating-webhook-configuration

ValidatingWebhookConfiguration
  lws-validating-webhook-configuration

```
