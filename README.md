# PodSense Local Deployment with Kind

## 1. Create a Local Kubernetes Cluster

```bash
kind create cluster --name project-podsense
```

---

## 2. Add Helm Repositories

Add the required Helm repositories and update them:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add ingress https://kubernetes.github.io/ingress-nginx
helm repo update
```

---

## 3. Deploy Monitoring and Ingress

### a) Prometheus & Grafana

Create a namespace for monitoring and install the Prometheus stack:

```bash
kubectl create namespace monitoring
helm install -n monitoring prometheus prometheus-community/kube-prometheus-stack
```

### b) Ingress Controller

Create a namespace for ingress and deploy NGINX Ingress:

```bash
kubectl create namespace ingress
helm install -n ingress ingress ingress-nginx/ingress-nginx --set controller.service.type=NodePort
```

---

## 4. Expose Prometheus and Grafana Locally

Forward the services to local ports:

```bash
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
```

- Grafana: [http://localhost:3000](http://localhost:3000)
- Prometheus: [http://localhost:9090](http://localhost:9090)

---

## 5. Deploy PodSense Application

### Option 1: Using Raw YAML

```bash
kubectl create namespace podsense
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/ingress.yaml -n ingress
```

### Option 2: Using Helm

```bash
kubectl create namespace podsense
helm install podsense helm/podsense -n podsense --create-namespace -f helm/podsense/values-nodeport.yaml
```

---

## 6. View Grafana Configuration

```bash
./info.sh
```

---

## 7. Generate Traffic

### Direct to the PodSense Service

```bash
hey -disable-keepalive -n 50 -c 10 \
  -m POST \
  -H "Content-Type: application/json" \
  -d '{"url":"https://static.vecteezy.com/system/resources/previews/045/926/094/non_2x/a-hat-isolated-on-white-background-vector.jpg"}' \
  http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'):30001/predict/url
```

### Through Ingress

```bash
hey -disable-keepalive -n 50 -c 5 \
  -m POST \
  -H "Content-Type: application/json" \
  -d '{"url":"https://static.vecteezy.com/system/resources/previews/045/926/094/non_2x/a-hat-isolated-on-white-background-vector.jpg"}' \
  http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'):$(kubectl get svc ingress-ingress-nginx-controller -n ingress -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')/predict/url
```

---

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
