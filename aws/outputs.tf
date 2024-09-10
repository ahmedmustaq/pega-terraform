output "kubernetes_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.primary.name
}

output "kubernetes_cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = aws_eks_cluster.primary.endpoint
}

output "kubernetes_cluster_version" {
  description = "The Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.primary.version
}




