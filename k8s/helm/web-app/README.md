# web-app Helm Chart

Generic web app chart extracted from k8s/test-pod.yaml with ConfigMap, Deployment, Service, and Ingress.

## Install

```bash
helm install my-web ./k8s/charts/web-app \
  --set nameOverride=nginx-200 \
  --set ingress.enabled=true
```

## Values

Key values (see values.yaml for full list):

- replicaCount: 1
- image.repository: nginx
- image.tag: alpine
- service.type: ClusterIP
- service.port: 80
- ingress.enabled: true
- ingress.className: alb
- configMap.enabled: true

## Example from repo

This chart defaults to the nginx 200 example. Adjust values.yaml or set flags on install.

