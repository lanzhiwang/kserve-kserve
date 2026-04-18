# KServe Installation

## Knative Mode

```bash
kustomize build config/overlays/standalone/kserve > learn/operator/kServe_knative_mode.yaml

Namespace
  kserve

CustomResourceDefinition
  clusterservingruntimes.serving.kserve.io
  clusterstoragecontainers.serving.kserve.io
  inferencegraphs.serving.kserve.io
  inferenceservices.serving.kserve.io
  servingruntimes.serving.kserve.io
  trainedmodels.serving.kserve.io

ServiceAccount
  kserve-controller-manager

Role
  kserve-leader-election-role

ClusterRole
  kserve-manager-role
  kserve-proxy-role

RoleBinding
  kserve-leader-election-rolebinding

ClusterRoleBinding
  kserve-manager-rolebinding
  kserve-proxy-rolebinding

ConfigMap
  inferenceservice-config

Secret
  kserve-webhook-server-secret

Service
  kserve-controller-manager-metrics-service
  kserve-controller-manager-service
  kserve-webhook-server-service

Deployment
  kserve-controller-manager

apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  labels:
    app.kubernetes.io/component: kserve
    app.kubernetes.io/name: kserve
  name: serving-cert
  namespace: kserve

apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: selfsigned-issuer
  namespace: kserve

ClusterStorageContainer
  default

MutatingWebhookConfiguration
  inferenceservice.serving.kserve.io

ValidatingWebhookConfiguration
  clusterservingruntime.serving.kserve.io
  inferencegraph.serving.kserve.io
  inferenceservice.serving.kserve.io
  servingruntime.serving.kserve.io
  trainedmodel.serving.kserve.io

```


## Standard Mode

## Install ClusterServingRuntimes

```bash
kustomize build config/runtimes > learn/operator/kServe_runtimes.yaml

ClusterServingRuntime
  kserve-huggingfaceserver
  kserve-huggingfaceserver-multinode
  kserve-lgbserver
  kserve-mlserver
  kserve-paddleserver
  kserve-pmmlserver
  kserve-predictiveserver
  kserve-sklearnserver
  kserve-tensorflow-serving
  kserve-torchserve
  kserve-tritonserver
  kserve-xgbserver

```
