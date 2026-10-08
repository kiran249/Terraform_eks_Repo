# Remote backend to store Terraform state in S3
terraform {
  backend "s3" {
    bucket       = "terraform-state-kiran-2026"
    key          = "eks/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
