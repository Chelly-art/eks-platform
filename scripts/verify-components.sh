#!/usr/bin/env bash
set -euo pipefail
aws eks update-kubeconfig --name "${CLUSTER_NAME:?}" --region "${AWS_REGION:?}"
BAD=$(helm list -A --all -o json | jq -r '.[] | select(.status!="deployed") | .name')
[ -z "$BAD" ] || { echo "Not deployed: $BAD"; exit 1; }
for ns in tigera-operator calico-system cert-manager traefik kyverno capsule-system monitoring; do
  for r in $(kubectl get deploy,ds,sts -n "$ns" -o name); do
    kubectl -n "$ns" rollout status "$r" --timeout=10m
  done
done
if [ "${ENABLE_KATA:-true}" = "true" ]; then
  kubectl -n kube-system rollout status ds/kata-deploy --timeout=15m || true
  kubectl get runtimeclass
fi
helm list -A
kubectl get pods -A
echo "Components ready"
