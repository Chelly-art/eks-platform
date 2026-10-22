variable "region" {
  type    = string
  default = "eu-west-2"
}
variable "cluster_name" {
  type    = string
  default = "platform-eks"
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "single_nat_gateway" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = { ManagedBy = "terraform", Project = "eks-platform" }
}
