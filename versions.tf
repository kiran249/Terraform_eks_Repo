terraform {
  # S3 native state locking (use_lockfile in backend.tf) requires Terraform >= 1.10
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # terraform-aws-modules/vpc v6.x needs >= 6.28, eks v21.x needs >= 6.20
      version = ">= 6.28, < 7.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
