# EKS platform

Layers (applied in order by `.github/workflows/eks-platform.yml`):

1. `vpc/` – VPC, 3 AZ public/private subnets, NAT
2. `eks/` – EKS 1.36, AL2023 managed nodes, add-ons: vpc-cni, kube-proxy, coredns (+ optional Kata metal node group)
3. `components/` – Helm: Calico, cert-manager, Traefik, Kyverno, Capsule, Capsule Proxy, Kata, kube-prometheus-stack

State + locking: one S3 bucket, `use_lockfile = true` (Terraform >= 1.10, no DynamoDB).

## Setup
- Repo variable: `TF_STATE_BUCKET` (globally unique name; created by the workflow if missing)
- Repo secret: `AWS_ROLE_ARN` (IAM role trusted for GitHub OIDC)
- Environments: `plan-only`, `infrastructure` (add required reviewers here to gate apply/destroy)
- Run: Actions -> "EKS platform" -> action = plan | apply | destroy

Note: `plan` on `eks`/`components` needs the previous layer already applied (they read its state).
