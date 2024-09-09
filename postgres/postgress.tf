provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_instance" "docker_postgres_pljava" {
  name         = "docker-postgres-pljava-instance"
  machine_type = var.machine_type
  zone         = var.zone
  allow_stopping_for_update = true

  # Define the boot disk and OS image (Ubuntu in this case)
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

  # Metadata for startup script to install Docker and run the PostgreSQL-PL/Java container
  metadata = {
    startup-script = <<-EOF
      #!/bin/bash
      # Update package list and install Docker
      sudo apt-get update
      sudo apt-get install -y docker.io

      # Enable and start Docker service
      sudo systemctl enable docker
      sudo systemctl start docker

      # Run PostgreSQL-PL/Java container using the pega/postgres-pljava-openjdk:11 image
      sudo docker run -d \
        --name postgres-pljava \
        -e POSTGRES_USER=postgres \
        -e POSTGRES_PASSWORD=postgres \
        -e POSTGRES_DB=postgres \
        -p 5432:5432 \
        -v /var/lib/postgresql-persist/data:/var/lib/postgresql/data \
        pegasystems/postgres-pljava-openjdk:11

      # Expose PostgreSQL port
      sudo ufw allow 5432
    EOF
  }

  tags = ["postgres-server"]

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# Optional: Firewall rule to allow external access to PostgreSQL
resource "google_compute_firewall" "allow_postgres" {
  name    = "allow-postgres"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = ["0.0.0.0/0"]  # Restrict this for better security
  target_tags   = ["postgres-server"]
}
