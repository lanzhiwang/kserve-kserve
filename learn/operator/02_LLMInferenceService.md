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
