data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # /24 subnets carved out of var.vpc_cidr: private 10.0.1.0/24, 10.0.2.0/24 ... public 10.0.101.0/24, 10.0.102.0/24 ...
  private_subnets = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 1)]
  public_subnets  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 101)]

  account_id     = data.aws_caller_identity.current.account_id
  account_root   = "arn:aws:iam::${local.account_id}:root"
  caller_is_root = endswith(data.aws_caller_identity.current.arn, ":root")

  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}
