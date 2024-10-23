provider "google" {
  project = var.project_id
  region  = var.region
}
terraform {
  backend "gcs" {
    bucket  = "terraform-pega"
    prefix  = "terraform/gke/state"
  }
}
# Enable the Kubernetes Engine API
resource "google_project_service" "enable_kubernetes_api" {
  depends_on = [google_project_service.enable_compute_api]
  project = var.project_id
  service = "container.googleapis.com"
 
}

resource "google_project_service" "enable_cloud_resource_manager" {
  depends_on = [google_project_service.enable_compute_api]
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"
}


# (Optional) Enable other related APIs if needed
resource "google_project_service" "enable_compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
   # Prevent this resource from being destroyed
 
}

resource "google_service_account" "terraform_sa" {
  account_id   = "terraform-sa"
  display_name = "Terraform Service Account"
}

resource "google_project_iam_member" "terraform_sa_role" {
  project = var.project_id
  role    = "roles/editor"  # Assign the "Editor" role or any other roles you need
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}


resource "google_service_account_key" "terraform_sa_key" {
  service_account_id = google_service_account.terraform_sa.name
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

resource "google_project_iam_member" "kubernetes_admin_role" {
  project = var.project_id
  role    = "roles/container.admin"  # Kubernetes Engine Admin
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

resource "google_project_iam_member" "compute_admin_role" {
  project = var.project_id
  role    = "roles/compute.admin"  # Compute Admin
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
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

