terraform {
  backend "gcs" {
    bucket  = "terraform-pega"
    prefix  = "terraform/state"
  }
}
provider "google" {
  project = var.project_id
  region  = var.region
}




resource "google_service_account_key" "terraform_sa_key" {
  service_account_id = google_service_account.terraform_sa.name
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

resource "google_container_cluster" "primary" {
  depends_on = [google_project_service.enable_kubernetes_api]	
  name     = var.cluster_name
  location = var.region
  deletion_protection = false
  initial_node_count = 1

  node_config {
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  remove_default_node_pool = true
}

resource "google_container_node_pool" "primary_nodes" {
  depends_on = [google_project_service.enable_kubernetes_api]		
  name       = "primary-node-pool"
  cluster    = google_container_cluster.primary.name
  location   = google_container_cluster.primary.location
  node_count = var.node_count


  node_config {
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

