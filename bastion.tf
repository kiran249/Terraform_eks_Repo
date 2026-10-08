# -----------------------------------------------------------------------------
# Bastion Host - EC2 instance in a public subnet for EKS cluster access
# -----------------------------------------------------------------------------

# --- SSH Key Pair (generated via TLS provider) ---

resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion" {
  key_name   = "${var.cluster_name}-bastion-key"
  public_key = tls_private_key.bastion.public_key_openssh
}

# --- Security Group ---

resource "aws_security_group" "bastion" {
  name_prefix = "${var.cluster_name}-bastion-"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_allowed_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-bastion-sg"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# --- IAM Role for Bastion (to interact with EKS) ---

resource "aws_iam_role" "bastion" {
  name = "${var.cluster_name}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-bastion-role"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "bastion_eks" {
  name = "${var.cluster_name}-bastion-eks-policy"
  role = aws_iam_role.bastion.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.cluster_name}-bastion-profile"
  role = aws_iam_role.bastion.name
}

# --- Look up the latest Amazon Linux 2023 AMI ---

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# --- EC2 Instance ---

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.bastion_instance_type
  key_name               = aws_key_pair.bastion.key_name
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system packages
    dnf update -y

    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/

    # Install AWS CLI v2 (already present on AL2023, but ensure latest)
    dnf install -y aws-cli-2

    # Install Helm
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # Configure kubeconfig for the EKS cluster
    sudo -u ec2-user bash -c 'aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}'
  EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 enforced
    http_put_response_hop_limit = 2
  }

  tags = {
    Name        = "${var.cluster_name}-bastion"
    Environment = "dev"
    Project     = "eks"
    ManagedBy   = "terraform"
  }
}

# --- Allow bastion to reach the EKS API server ---

resource "aws_security_group_rule" "eks_from_bastion" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = aws_security_group.bastion.id
  description              = "Allow bastion host to access EKS API"
}
