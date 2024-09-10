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

output "service_account_arn" {
  description = "The ARN of the created IAM role for the service account"
  value       = aws_iam_role.terraform_sa.arn
}

output "service_account_role_policy_arn" {
  description = "The ARN of the IAM policy attached to the service account role"
  value       = aws_iam_role_policy_attachment.terraform_sa_policy.policy_arn
}
