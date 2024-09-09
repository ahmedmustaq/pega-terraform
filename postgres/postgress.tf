terraform {
  backend "gcs" {
    bucket  = "terraform-pega"
    prefix  = "terraform/postgres"
  }
}
provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_instance" "default" {
  name         = "postgres-instance"
  machine_type = var.machine_type
  zone         = var.zone

  # Define the boot disk and OS image
  boot_disk {
    initialize_params {
      image = "ubuntu-2004-focal-v20210927"
    }
  }

  # Network interface configuration
  network_interface {
    network = "default"
    access_config {}
  }

  # Metadata for startup script to install PostgreSQL
  metadata = {
    startup-script = <<-EOF
      #!/bin/bash
      sudo apt-get update
      sudo apt-get install -y postgresql postgresql-contrib
      sudo systemctl start postgresql
      sudo systemctl enable postgresql
	  # Set a password for the postgres user
      sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"
    EOF
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_compute_firewall" "postgres" {
  name    = "allow-postgres"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["postgres-server"]
}

resource "google_service_account_key" "terraform_sa_key" {
  service_account_id = google_service_account.terraform_sa.name
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

resource "google_project_iam_member" "compute_admin_role" {
  project = var.project_id
  role    = "roles/compute.admin"  # Compute Admin
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

resource "google_service_account" "terraform_sa" {
  account_id   = "terraform-sa"
  display_name = "Terraform Service Account"
}
