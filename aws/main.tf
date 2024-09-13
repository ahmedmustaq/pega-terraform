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

# Data source to reference the existing VPC
data "aws_vpc" "main" {
  id = "tfer--vpc-0f3367c2875db3056"  # Replace with your actual VPC ID
}

# Data sources to reference the existing subnets
data "aws_subnet" "subnet_1" {
  id = "tfer--subnet-012790848136eab91"  # Replace with your actual subnet ID
}

data "aws_subnet" "subnet_2" {
  id = "tfer--subnet-02a7a49446dc51f76"  # Replace with your actual subnet ID
}

data "aws_subnet" "subnet_3" {
  id = "tfer--subnet-04b456fabf695a095"  # Replace with your actual subnet ID
}

# Data source to reference the existing security group
data "aws_security_group" "eks_security_group" {
  id = "sg-01a444757bf6a08ac"  # Replace with your actual security group ID
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  ]

  tags = {
    Name = "eks-cluster-role"
  }
}

# EKS Node Group IAM Role
resource "aws_iam_role" "eks_node_group_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]

  tags = {
    Name = "eks-node-group-role"
  }
}

# EKS Cluster
resource "aws_eks_cluster" "pega_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.30"

  vpc_config {
    subnet_ids         = [data.aws_subnet.subnet_1.id, data.aws_subnet.subnet_2.id, data.aws_subnet.subnet_3.id]
    security_group_ids = [data.aws_security_group.eks_security_group.id]
    endpoint_public_access = true
    endpoint_private_access = true
  }
}

# EKS Node Group
resource "aws_eks_node_group" "pega_node_group" {
  cluster_name    = var.nodegroup_name
  node_group_name = "pega-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  subnet_ids = [data.aws_subnet.subnet_1.id, data.aws_subnet.subnet_2.id, data.aws_subnet.subnet_3.id]

  tags = {
    Name = "pega-node-group"
  }
}
