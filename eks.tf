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

  # Cluster-admin for the identity running Terraform (e.g. the Jenkins IAM user)
  enable_cluster_creator_admin_permissions = true

  access_entries = merge(
    {
      bastion = {
        principal_arn = aws_iam_role.bastion.arn
        type          = "STANDARD"

        policy_associations = {
          cluster_admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    },
    # Account root for AWS console access. Skipped when Terraform itself runs as root,
    # because the creator entry above already covers that principal (duplicates fail).
    var.grant_account_root_admin && !local.caller_is_root ? {
      root = {
        principal_arn = local.account_root
        type          = "STANDARD"

        policy_associations = {
          cluster_admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    } : {}
  )

  addons = {
    coredns = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
    }

    kube-proxy = {
      most_recent                 = true
      before_compute              = true
      resolve_conflicts_on_create = "OVERWRITE"
    }

    vpc-cni = {
      most_recent                 = true
      before_compute              = true
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

      subnet_ids = module.vpc.private_subnets

      # The module uses a custom launch template, where `disk_size` is ignored,
      # so the root volume size must be set through block_device_mappings.
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.node_disk_size
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      labels = {
        Environment = var.environment
      }

      tags = {
        Name = "${var.cluster_name}-nodes"
      }
    }
  }

  tags = local.common_tags
}
