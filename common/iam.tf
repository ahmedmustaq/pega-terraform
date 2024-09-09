provider "google" {
  project = var.project_id
  region  = var.region
}
# Enable the Kubernetes Engine API
resource "google_project_service" "enable_kubernetes_api" {
  project = var.project_id
  service = "container.googleapis.com"
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