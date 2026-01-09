### Start kind cluster

```bash
kind create cluster --name project-podsense
```

### Add prometheus, grafana and nginx-ingress to helm

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo up
```

### Deploy prometheus, grafana and nginx-ingress to cluster.

```bash
helm install prometheus prometheus-community/kube-prometheus-stack
helm install nginx-ingress ingress-nginx/ingress-nginx --set controller.service.type=NodePort
```

### Once these both are up and running, expose prometheus-server and grafana

```bash
kubectl port-forward svc/prometheus-grafana 3000:80
kctl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090
```

### Deploy application and Ingress

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/ingress.yaml
```

### Get information

```bash
./info.sh
```

### Generating traffic with `hey` on service

```bash
hey -disable-keepalive -n 50 -c 10 \
    -m POST \
    -H "Content-Type: application/json" \
    -d '{"url":"https://static.vecteezy.com/system/resources/previews/045/926/094/non_2x/a-hat-isolated-on-white-background-vector.jpg"}' \
    http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'):30001/predict/url
```

### Generating traffci with hey with ingress

```bash
hey -disable-keepalive -n 200 -c 10 \
    -m POST \
    -H "Content-Type: application/json" \
    -d '{"url":"https://static.vecteezy.com/system/resources/previews/045/926/094/non_2x/a-hat-isolated-on-white-background-vector.jpg"}' \
    http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'): \
    $(kubectl get svc nginx-ingress-ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')/predict/url
```

### Get the latency with `PROMQL` on prometheus-server

```bash
  histogram_quantile(0.95, sum by(le) (rate(http_request_duration_second_bucket[10m])))
```

### Get throttling on prometheus-server

```bash
rate(container_cpu_cfs_throttled_seconds_total[10m]) / rate(container_cpu_cfs_throttled_periods_total[10m])
```
