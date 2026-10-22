# Install order: calico -> cert-manager -> everything else (capsule-proxy after capsule)

# ---------- Calico (policy-only on top of AWS VPC CNI) ----------
resource "helm_release" "calico" {
  name             = "calico"
  namespace        = "tigera-operator"
  create_namespace = true
  repository       = "https://docs.tigera.io/calico/charts"
  chart            = "tigera-operator"
  version          = var.calico_chart_version
  timeout          = 900

  values = [yamlencode({
    installation = {
      kubernetesProvider = "EKS"
      cni                = { type = "AmazonVPC" }
    }
  })]
}

# ---------- cert-manager ----------
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_chart_version
  timeout          = 900

  values = [yamlencode({ crds = { enabled = true } })]

  depends_on = [helm_release.calico]
}

# ---------- Traefik ----------
resource "helm_release" "traefik" {
  name             = "traefik"
  namespace        = "traefik"
  create_namespace = true
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.traefik_chart_version
  timeout          = 900

  values = [yamlencode({
    service = {
      type = "LoadBalancer"
      annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
      }
    }
  })]

  depends_on = [helm_release.cert_manager]
}

# ---------- Kyverno ----------
resource "helm_release" "kyverno" {
  name             = "kyverno"
  namespace        = "kyverno"
  create_namespace = true
  repository       = "https://kyverno.github.io/kyverno/"
  chart            = "kyverno"
  version          = var.kyverno_chart_version
  timeout          = 900

  depends_on = [helm_release.cert_manager]
}

# ---------- Capsule ----------
resource "helm_release" "capsule" {
  name             = "capsule"
  namespace        = "capsule-system"
  create_namespace = true
  repository       = "https://projectcapsule.github.io/charts"
  chart            = "capsule"
  version          = var.capsule_chart_version
  timeout          = 900

  depends_on = [helm_release.cert_manager]
}

# ---------- Capsule Proxy ----------
resource "helm_release" "capsule_proxy" {
  name       = "capsule-proxy"
  namespace  = "capsule-system"
  repository = "https://projectcapsule.github.io/charts"
  chart      = "capsule-proxy"
  version    = var.capsule_proxy_chart_version
  timeout    = 900

  depends_on = [helm_release.capsule]
}

# ---------- Kata Containers (runs on the metal node group) ----------
resource "helm_release" "kata" {
  count = var.enable_kata ? 1 : 0

  name       = "kata-deploy"
  namespace  = "kube-system"
  repository = "oci://ghcr.io/kata-containers/kata-deploy-charts"
  chart      = "kata-deploy"
  version    = var.kata_chart_version
  timeout    = 900

  values = [yamlencode({
    nodeSelector = { "katacontainers.io/kata-runtime" = "true" }
  })]

  depends_on = [helm_release.calico]
}

# ---------- Monitoring: Prometheus, Alertmanager, Grafana ----------
resource "random_password" "grafana" {
  length  = 24
  special = false
}

resource "helm_release" "monitoring" {
  name             = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.monitoring_chart_version
  timeout          = 1200

  values = [yamlencode({
    grafana = { adminPassword = random_password.grafana.result }
    # EKS control plane is managed: these targets are not scrapeable
    kubeEtcd              = { enabled = false }
    kubeControllerManager = { enabled = false }
    kubeScheduler         = { enabled = false }
    prometheus = {
      prometheusSpec = { retention = "7d" } # emptyDir storage; add EBS CSI + PVC for persistence
    }
  })]

  depends_on = [helm_release.cert_manager]
}
