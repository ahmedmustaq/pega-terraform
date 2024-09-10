terraform {
  backend "s3" {
    bucket = "terraform-pega"
    key    = "terraform/eks/state"
	region = "eu-west-2"
  }
}

provider "aws" {
  region = var.region
}

# Enable the necessary IAM roles and policies for EKS
resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Service Account for Terraform
resource "aws_iam_role" "terraform_sa" {
  name = "terraform-sa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "terraform_sa_policy" {
  role       = aws_iam_role.terraform_sa.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# EKS Cluster
resource "aws_eks_cluster" "primary" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_policy
  ]
}

# EKS Node Group
resource "aws_eks_node_group" "primary_nodes" {
  cluster_name    = aws_eks_cluster.primary.name
  node_group_name = "primary-node-group"
  node_role_arn   = aws_iam_role.terraform_sa.arn
  subnet_ids      = var.subnet_ids
  instance_types  = [var.instance_type]

  scaling_config {
    desired_size = var.node_count
    max_size     = var.node_count
    min_size     = 1
  }
}

# Optional: Allow Terraform Service Account to manage EKS
resource "aws_iam_role_policy_attachment" "eks_admin_policy" {
  role       = aws_iam_role.terraform_sa.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}
