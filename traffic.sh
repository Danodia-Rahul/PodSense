#!/usr/bin/env bash

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

GRAFANA_PORT=$(kubectl get svc -o jsonpath='{.items[?(@.metadata.name=="grafana-ext")].spec.ports[0].nodePort}')

PROMETHEUS_SERVER_PORT=$(kubectl get svc -o jsonpath='{.items[?(@.metadata.name=="prometheus-server-ext")].spec.ports[0].nodePort}')

echo "prometheus server can be accessed at: http://$NODE_IP:$PROMETHEUS_SERVER_PORT"
echo "grafana can be accessed at: http://$NODE_IP:$GRAFANA_PORT"

echo ""
echo "generating traffic...."

for i in {1..50}; do
	curl -s -X POST \
		"http://$NODE_IP:30001/predict" \
		-H 'accept: application/json' \
		-F 'image_url=https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTq3ucAy2Q8YBkU-UPYO-b3wGFuPdtW08inZA&s' \
		>/dev/null
done

echo "done"
