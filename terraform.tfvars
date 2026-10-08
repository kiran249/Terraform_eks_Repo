aws_region         = "us-east-1"
cluster_name       = "dev-eks-cluster"
vpc_cidr           = "10.0.0.0/16"
kubernetes_version = "1.33"

node_instance_types = [
  "t3.medium"
]

node_min_size     = 2
node_max_size     = 4
node_desired_size = 2
