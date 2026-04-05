#!/usr/bin/env bash

GRAFANA_USERNAME=$(kubectl get secret prometheus-grafana -n monitoring -o jsonpath='{.data.admin-user}' | base64 --decode)
GRAFANA_PASSWORD=$(kubectl get secret prometheus-grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 --decode)

echo "grafana login username: $GRAFANA_USERNAME"
echo "grafana login password: $GRAFANA_PASSWORD"

APPLICATION_ADDR=$(kubectl get svc ingress-ingress-nginx-controller -n podsense -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

if [[ -n "$APPLICATION_ADDR" ]]; then
	echo "application address: http://$APPLICATION_ADDR/docs"
fi
