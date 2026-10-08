aws_region  = "us-east-1"
environment = "dev"
project     = "eks"

# Networking
vpc_cidr = "10.0.0.0/16"
az_count = 2

# EKS
cluster_name       = "dev-eks-cluster"
kubernetes_version = "1.33"

node_instance_types = [
  "t3.medium"
]

node_min_size     = 2
node_max_size     = 4
node_desired_size = 2
node_disk_size    = 30

# Bastion
bastion_instance_type = "t3.micro"
bastion_allowed_cidr  = "0.0.0.0/0" # TODO: restrict to your public IP, e.g. "203.0.113.10/32"
bastion_disk_size     = 30
