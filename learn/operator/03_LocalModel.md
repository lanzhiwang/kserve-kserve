# LocalModel Installation

```bash

kustomize build config/overlays/addons/localmodel > learn/operator/localmodel.yaml

CustomResourceDefinition
  localmodelcaches.serving.kserve.io
  localmodelnodegroups.serving.kserve.io
  localmodelnodes.serving.kserve.io

ServiceAccount
  kserve-localmodel-controller-manager
  kserve-localmodelnode-agent

ClusterRole
  kserve-localmodel-manager-role
  kserve-localmodelnode-agent-role

ClusterRoleBinding
  kserve-localmodel-manager-rolebinding
  kserve-localmodelnode-agent-rolebinding

Service
  localmodel-webhook-server-service

Deployment
  kserve-localmodel-controller-manager

DaemonSet
  kserve-localmodelnode-agent

apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  labels:
    app.kubernetes.io/component: localmodel
    app.kubernetes.io/name: kserve
  name: localmodel-serving-cert
  namespace: kserve

ValidatingWebhookConfiguration
  localmodelcache.serving.kserve.io


```

