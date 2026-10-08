module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_public_access  = true
  endpoint_private_access = true

  enable_irsa = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_cluster_creator_admin_permissions = true

  access_entries = {
    bastion = {
      principal_arn = aws_iam_role.bastion.arn
      type          = "STANDARD"

      policy_associations = {
        cluster_admin = {
          policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    root = {
      principal_arn = "arn:aws:iam::077542728885:root"
      type          = "STANDARD"

      policy_associations = {
        cluster_admin = {
          policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  addons = {
    coredns = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
    }

    kube-proxy = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
    }

    vpc-cni = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
    }

    eks-pod-identity-agent = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
    }
  }

  eks_managed_node_groups = {
    "${var.cluster_name}" = {
      name = "${var.cluster_name}-ng"

      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      capacity_type = "ON_DEMAND"

      disk_size = 30

      subnet_ids = module.vpc.private_subnets

      labels = {
        Environment = "dev"
      }

      tags = {
        Name        = "${var.cluster_name}-nodes"
        Environment = "dev"
        ManagedBy   = "terraform"
      }
    }
  }

  tags = {
    Environment = "dev"
    Project     = "eks"
    ManagedBy   = "terraform"
  }
}
