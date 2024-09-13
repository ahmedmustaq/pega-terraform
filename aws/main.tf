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
 kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = "10.100.0.0/16"
  }

  name     = var.cluster_name
  role_arn = "arn:aws:iam::329599638099:role/eks-cluster-role"
  version  = "1.30"

  vpc_config {
    endpoint_private_access = "true"
    endpoint_public_access  = "true"
    public_access_cidrs     = ["0.0.0.0/0"]
    security_group_ids      = ["sg-01a444757bf6a08ac"]
    subnet_ids              = ["${data.terraform_remote_state.subnet.outputs.aws_subnet_tfer--subnet-012790848136eab91_id}", "${data.terraform_remote_state.subnet.outputs.aws_subnet_tfer--subnet-02a7a49446dc51f76_id}", "${data.terraform_remote_state.subnet.outputs.aws_subnet_tfer--subnet-04b456fabf695a095_id}"]
  }
}

# EKS Node Group
resource "aws_eks_node_group" "tfer--pega-node" {
  ami_type        = "AL2_x86_64"
  capacity_type   = "ON_DEMAND"
  cluster_name    = "${aws_eks_cluster.tfer--pega-cluster.name}"
  disk_size       = "20"
  instance_types  = ["t3.medium"]
  node_group_name =  var.node_group_name
  node_role_arn   = "arn:aws:iam::329599638099:role/eks-node-group-role"
  release_version = "1.30.2-20240904"

  scaling_config {
    desired_size = "2"
    max_size     = "2"
    min_size     = "2"
  }

  subnet_ids = ["subnet-012790848136eab91", "subnet-02a7a49446dc51f76", "subnet-04b456fabf695a095"]

  update_config {
    max_unavailable = "1"
  }

  version = "1.30"
}