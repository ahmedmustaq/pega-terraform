output "kubernetes_cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "kubernetes_cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = google_container_cluster.primary.endpoint
}

output "kubernetes_cluster_master_version" {
  description = "The master version of the GKE cluster"
  value       = google_container_cluster.primary.master_version
}

output "service_account_email" {
  description = "The email of the created service account"
  value       = google_service_account.terraform_sa.email
}

output "service_account_private_key" {
  description = "The private key of the created service account"
  value       = base64decode(google_service_account_key.terraform_sa_key.private_key)
  sensitive   = true
}
