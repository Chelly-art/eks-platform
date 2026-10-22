variable "region" {
  type    = string
  default = "eu-west-2"
}
variable "cluster_name" {
  type    = string
  default = "platform-eks"
}
variable "kubernetes_version" {
  type    = string
  default = "1.36"
}
variable "state_bucket" { type = string }
variable "vpc_state_key" {
  type    = string
  default = "vpc/terraform.tfstate"
}
variable "public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
variable "node_instance_types" {
  type    = list(string)
  default = ["m6i.large"]
}
variable "node_min_size" {
  type    = number
  default = 2
}
variable "node_max_size" {
  type    = number
  default = 4
}
variable "node_desired_size" {
  type    = number
  default = 2
}
variable "enable_kata_node_group" {
  type    = bool
  default = false
}
variable "kata_instance_types" {
  type    = list(string)
  default = ["c5.metal"]
}
variable "kata_desired_size" {
  type    = number
  default = 1
}
variable "tags" {
  type    = map(string)
  default = { ManagedBy = "terraform", Project = "eks-platform" }
}
