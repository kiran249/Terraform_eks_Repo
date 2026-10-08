provider "aws" {
  region = var.aws_region

  # Applied to every AWS resource created by this configuration (including modules)
  default_tags {
    tags = local.common_tags
  }
}
