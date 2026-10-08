# Remote backend to store Terraform state in S3
# Uncomment and configure this block before running in Jenkins
#
# Prerequisites:
#   1. Create an S3 bucket for state storage
#   2. Create a DynamoDB table for state locking (partition key: "LockID")
#   3. Run: terraform init -migrate-state
#
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "eks/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-lock"
#     encrypt        = true
#   }
# }
