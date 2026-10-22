terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
  backend "s3" {}
}

provider "aws" {
  region = var.region
  default_tags { tags = var.tags }
}

# Read the VPC layer's state (same S3 bucket)
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = var.vpc_state_key
    region = var.region
  }
}

locals {
  kata_group = var.enable_kata_node_group ? {
    kata = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.kata_instance_types # Kata needs bare metal (or nested virt)
      min_size       = 0
      max_size       = 2
      desired_size   = var.kata_desired_size
      labels = {
        "katacontainers.io/kata-runtime" = "true"
        "workload"                       = "kata"
      }
    }
  } : {}
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version # 1.36

  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  endpoint_public_access                   = true
  endpoint_public_access_cidrs             = var.public_access_cidrs
  endpoint_private_access                  = true
  enable_cluster_creator_admin_permissions = true

  # Core EKS add-ons
  addons = {
    vpc-cni    = { most_recent = true, before_compute = true }
    kube-proxy = { most_recent = true }
    coredns    = { most_recent = true }
  }

  eks_managed_node_groups = merge({
    default = {
      ami_type       = "AL2023_x86_64_STANDARD" # Amazon Linux 2023
      instance_types = var.node_instance_types
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
      labels         = { workload = "general" }
    }
  }, local.kata_group)
}
