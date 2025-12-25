#!/usr/bin/env bash

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

GRAFANA_PORT=$(kubectl get svc -o jsonpath='{.items[?(@.metadata.name=="grafana-ext")].spec.ports[0].nodePort}')

PROMETHEUS_SERVER_PORT=$(kubectl get svc -o jsonpath='{.items[?(@.metadata.name=="prometheus-server-ext")].spec.ports[0].nodePort}')

echo "prometheus server can be accessed at: http://$NODE_IP:$PROMETHEUS_SERVER_PORT"
echo "grafana can be accessed at: http://$NODE_IP:$GRAFANA_PORT"

GRAFANA_PASSWORD=$(kubectl get secret grafana -o jsonpath='{.data.admin-password}' | base64 --decode)
echo "grafana login password: $GRAFANA_PASSWORD"
