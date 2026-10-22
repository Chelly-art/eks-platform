variable "region" {
  type    = string
  default = "us-east-1"
}
variable "state_bucket" { type = string }
variable "eks_state_key" {
  type    = string
  default = "eks/terraform.tfstate"
}
variable "enable_kata" {
  type    = bool
  default = false
}

# Chart versions: null = latest. Pin these after the first successful run.
variable "calico_chart_version" {
  type    = string
  default = null
}
variable "cert_manager_chart_version" {
  type    = string
  default = null
}
variable "traefik_chart_version" {
  type    = string
  default = null
}
variable "kyverno_chart_version" {
  type    = string
  default = null
}
variable "capsule_chart_version" {
  type    = string
  default = null
}
variable "capsule_proxy_chart_version" {
  type    = string
  default = null
}
variable "kata_chart_version" {
  type    = string
  default = null
}
variable "monitoring_chart_version" {
  type    = string
  default = null
}
