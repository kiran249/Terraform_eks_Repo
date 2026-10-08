# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name, used for tagging and node labels"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name, used for tagging"
  type        = string
  default     = "eks"
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "VPC CIDR (must be a /16 so the /24 subnets can be derived from it)"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && endswith(var.vpc_cidr, "/16")
    error_message = "vpc_cidr must be a valid /16 CIDR block, e.g. 10.0.0.0/16."
  }
}

variable "az_count" {
  description = "Number of availability zones to spread the subnets across"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "EKS requires at least 2 availability zones; az_count must be between 2 and 4."
  }
}

# -----------------------------------------------------------------------------
# EKS
# -----------------------------------------------------------------------------

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "dev-eks-cluster"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,17}$", var.cluster_name))
    error_message = "cluster_name must start with a letter, contain only letters, digits and hyphens, and be at most 18 characters (longer names overflow the 38-character IAM role name_prefix limit of the node group role)."
  }
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.33"
}

variable "grant_account_root_admin" {
  description = "Grant the AWS account root principal cluster-admin access (lets IAM users/roles with EKS console permissions view cluster resources)"
  type        = bool
  default     = true
}

variable "node_instance_types" {
  description = "EKS node instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2

  validation {
    condition     = var.node_desired_size >= var.node_min_size && var.node_desired_size <= var.node_max_size
    error_message = "node_desired_size must be between node_min_size and node_max_size."
  }
}

variable "node_disk_size" {
  description = "Root EBS volume size (GiB) for worker nodes"
  type        = number
  default     = 30
}

# -----------------------------------------------------------------------------
# Bastion
# -----------------------------------------------------------------------------

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "bastion_allowed_cidr" {
  description = "CIDR block allowed to SSH into the bastion host (restrict to your IP for security, e.g. 203.0.113.10/32)"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.bastion_allowed_cidr, 0))
    error_message = "bastion_allowed_cidr must be a valid CIDR block."
  }
}

variable "bastion_disk_size" {
  description = "Root EBS volume size (GiB) for the bastion host"
  type        = number
  default     = 30
}
