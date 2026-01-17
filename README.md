# PodSense Local Deployment with kind

## 1. Start Local Cluster

```bash
kind create cluster --name project-podsense
```

---

## 2. Add Helm Repos

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add ingress https://kubernetes.github.io/ingress-nginx
helm repo update
```

---

## 3. Deploy Monitoring and Ingress

```bash
helm install prometheus prometheus-community/kube-prometheus-stack
helm install ingress ingress-nginx/ingress-nginx --set controller.service.type=NodePort
```

---

## 4. Expose Prometheus & Grafana

```bash
kubectl port-forward svc/prometheus-grafana 3000:80
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090
```

- Grafana: `http://localhost:3000`
- Prometheus: `http://localhost:9090`

---

## 5. Deploy PodSense Application

**Using raw YAML:**

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/ingress.yaml
```

**Or using Helm:**

```bash
helm install podsense helm/podsense -n podsense --create-namespace
```

---

## 6. View Grafana Info

```bash
./info.sh
```

---

## 7. Generate Traffic

**Direct to service:**

```bash
hey -disable-keepalive -n 50 -c 10 \
  -m POST \
  -H "Content-Type: application/json" \
  -d '{"url":"https://static.vecteezy.com/system/resources/previews/045/926/094/non_2x/a-hat-isolated-on-white-background-vector.jpg"}' \
  http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'):30001/predict/url
```

**Via Ingress:**

```bash
hey -disable-keepalive -n 200 -c 10 \
  -m POST \
  -H "Content-Type: application/json" \
  -d '{"url":"https://static.vecteezy.com/system/resources/previews/045/926/094/non_2x/a-hat-isolated-on-white-background-vector.jpg"}' \
  http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'):$(kubectl get svc nginx-ingress-ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')/predict/url
```

### Working with AWS

```

```

### Get the latency with `PROMQL` on prometheus-server

```bash
  histogram_quantile(0.95, sum by(le) (rate(http_request_duration_second_bucket[10m])))
```

### Get throttling on prometheus-server

```bash
rate(container_cpu_cfs_throttled_seconds_total[10m]) / rate(container_cpu_cfs_throttled_periods_total[10m])
```
