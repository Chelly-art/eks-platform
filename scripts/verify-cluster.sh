#!/usr/bin/env bash
# Confirms cluster, version, add-ons and nodes are healthy.
set -euo pipefail
C="${CLUSTER_NAME:?}"; R="${AWS_REGION:?}"; WANT="${K8S_VERSION:-1.36}"
aws eks wait cluster-active --name "$C" --region "$R"
V=$(aws eks describe-cluster --name "$C" --region "$R" --query cluster.version --output text)
[ "$V" = "$WANT" ] || { echo "version $V != $WANT"; exit 1; }
aws eks update-kubeconfig --name "$C" --region "$R"
for a in vpc-cni kube-proxy coredns; do
  for i in $(seq 1 40); do
    S=$(aws eks describe-addon --cluster-name "$C" --addon-name "$a" --region "$R" --query addon.status --output text)
    [ "$S" = "ACTIVE" ] && break; sleep 15
  done
  echo "addon $a: $S"; [ "$S" = "ACTIVE" ] || exit 1
done
kubectl wait --for=condition=Ready nodes --all --timeout=15m
kubectl -n kube-system rollout status ds/aws-node ds/kube-proxy deploy/coredns --timeout=10m
kubectl get nodes -o wide
echo "Cluster ready"
