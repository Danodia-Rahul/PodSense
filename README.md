# PodSense

**Scalable ML Inference on Kubernetes (Local & AWS EKS)**

PodSense is a Kubernetes-native application that demonstrates scalable machine learning inference using modern cloud-native tooling. It supports **local-first development with Kind** and **production-style deployment on AWS EKS**, with built-in observability via **Prometheus and Grafana** and traffic management using **NGINX Ingress**.

---

## Project Goals

This project was built to demonstrate:

- Local-first Kubernetes development using Kind
- Promotion of workloads from local clusters to AWS EKS
- Infrastructure provisioning using Terraform
- Helm-based application packaging for environment consistency
- Observability using Prometheus and Grafana
- Load generation to evaluate application behavior under traffic

---

## Architecture Overview

PodSense is designed around common production patterns:

- Kubernetes orchestration (Kind for local, EKS for cloud)
- Helm-based application packaging
- Prometheus and Grafana for monitoring and metrics
- NGINX Ingress Controller for HTTP traffic routing
- Terraform for infrastructure provisioning on AWS
- Load testing with `hey`

The inference service uses an **ONNX-based image classification model** to simulate a realistic CPU-bound workload.

---

## Prerequisites

Ensure the following tools are installed:

- Docker
- kind
- kubectl
- helm
- terraform
- awscli
- hey
- An AWS account with appropriate IAM permissions (for EKS deployment)

---

## Local Deployment (Kind)

### 1. Create a Local Kubernetes Cluster

```bash
kind create cluster --name project-podsense
```

Verify cluster access:

```bash
kubectl get nodes
```

---

### 2. Add Helm Repositories

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add ingress https://kubernetes.github.io/ingress-nginx
helm repo update
```

---

### 3. Deploy Monitoring and Ingress

#### Prometheus and Grafana

```bash
kubectl create namespace monitoring
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring
```

#### NGINX Ingress Controller

```bash
kubectl create namespace ingress
helm install ingress ingress-nginx/ingress-nginx \
  -n ingress \
  --set controller.service.type=NodePort
```

---

### 4. Access Monitoring Dashboards

Port-forward the services:

```bash
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
```

Access via browser:

- Grafana: [http://localhost:3000](http://localhost:3000)
- Prometheus: [http://localhost:9090](http://localhost:9090)

Key metrics to observe:

- WSS usage
- Pod CPU utilization during load tests
- Request latency
- Replica scaling behavior under sustained traffic

---

### 5. Deploy the PodSense Application

Raw Kubernetes manifests are used for rapid local iteration and learning, while Helm charts are used for production-style deployment and configuration management.

#### Option 1: Raw Kubernetes Manifests

```bash
kubectl create namespace podsense
kubectl apply -f k8s/deployment.yaml -n podsense
kubectl apply -f k8s/ingress.yaml -n ingress
```

#### Option 2: Helm (Recommended)

```bash
helm install podsense helm/podsense \
  -n podsense \
  --create-namespace \
  -f helm/podsense/values-nodeport.yaml
```

---

### 6. Retrieve Application Information

```bash
./info.sh
```

This script prints service endpoints and Grafana access details.

---

### 7. Generate Traffic

Traffic is generated to simulate concurrent inference requests and observe system behavior under load.

#### Direct Access via NodePort

```bash
hey -disable-keepalive -n 50 -c 10 \
  -m POST \
  -H "Content-Type: application/json" \
  -d '{"url":"https://static.vecteezy.com/system/resources/previews/045/926/094/non_2x/a-hat-isolated-on-white-background-vector.jpg"}' \
  http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'):30001/predict/url
```

#### Through NGINX Ingress

```bash
hey -disable-keepalive -n 50 -c 5 \
  -m POST \
  -H "Content-Type: application/json" \
  -d '{"url":"https://static.vecteezy.com/system/resources/previews/045/926/094/non_2x/a-hat-isolated-on-white-background-vector.jpg"}' \
  http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'):$(kubectl get svc ingress-ingress-nginx-controller -n ingress -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')/predict/url
```

---

## AWS Deployment (EKS)

AWS resources are provisioned for demonstration purposes and can be selectively enabled or destroyed to control costs.

### 1. Provision the EKS Cluster Using Terraform

```bash
cd infra/
terraform apply --auto-approve
```

---

### 2. Configure kubectl for EKS

```bash
aws eks update-kubeconfig --name podsense-eks-cluster
```

Verify connectivity:

```bash
kubectl get nodes
```

---

### 3. Deploy NGINX Ingress Controller

```bash
kubectl create namespace podsense
helm install ingress ingress-nginx/ingress-nginx \
  -n podsense \
  -f helm/podsense/values-ingress.yaml
```

---

### 4. Deploy PodSense to EKS

```bash
helm install podsense helm/podsense -n podsense
```

---

### 5. Retrieve Application and Monitoring Information

```bash
./info.sh
```

---

## Cleanup

### Delete Kubernetes Resources

```bash
kubectl delete ingress --all -A
kubectl delete svc --all -A
```

### Remove EKS Context and User from kubeconfig

```bash
kubectl config delete-context $(kubectl config get-context -o name | grep podsense)
kubectl config delete-user $(kubectl config get-users -o name | grep podsense)
```

---
