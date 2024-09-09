terraform {
  backend "gcs" {
    bucket  = "terraform-pega"
    prefix  = "terraform/common/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
