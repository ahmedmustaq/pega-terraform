provider "google" {
  project = var.project_id
  region  = var.region
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
  private_key_type   = "JSON"
}

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

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

