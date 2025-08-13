# main.tf

provider "google" {
  project = var.project_id
  region  = var.region
}

# Custom is not supported with juju https://github.com/juju/juju/issues/20321
# A global VPC Network
#resource "google_compute_network" "vpc" {
#  name                    = "${var.vpc_name}"
#  auto_create_subnetworks = false
#}
# A regional subnet for "public" resources
#resource "google_compute_subnetwork" "public" {
#  name          = "${var.environment_name}-public-subnet"
#  ip_cidr_range = var.public_subnet_cidr
#  region        = var.region
#  network       = google_compute_network.vpc.id
#}
# A regional subnet for "private" resources
#resource "google_compute_subnetwork" "private" {
#  name          = "${var.environment_name}-private-subnet"
#  ip_cidr_range = var.private_subnet_cidr
#  region        = var.region
#  network       = google_compute_network.vpc.id
#  private_ip_google_access = true
#}
#resource "google_compute_router" "router" {
#  name    = "${var.environment_name}-router"
#  network = google_compute_network.vpc.id
#  region  = var.region
#}
#resource "google_compute_router_nat" "nat" {
#  name                               = "${var.environment_name}-nat-gateway"
#  router                             = google_compute_router.router.name
#  region                             = var.region
#  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
#  nat_ip_allocate_option             = "AUTO_ONLY"
#
#  log_config {
#    enable = true
#    filter = "ERRORS_ONLY"
#  }
#  subnetwork {
#    name                    = google_compute_subnetwork.private.id
#    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
#  }
#}

# Firewall rule to allow SSH to the bastion host
resource "google_compute_firewall" "allow_ssh" {
  #depends_on  = [google_compute_network.vpc]
  name    = "bastion-allow-ssh"
  network = var.vpc_name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion-host"]
}

# Firewall rule to allow all inside private subnet
resource "google_compute_firewall" "juju_allow_internal" {
  #depends_on  = [google_compute_network.vpc]
  name    = "${var.environment_name}-allow-internal"
  network = var.vpc_name
  allow {
    protocol = "tcp"
    ports    = []
  }
  allow {
    protocol = "udp"
    ports    = []
  }
  source_ranges = [var.private_subnet_cidr]
}

# Static IP for the Bastion Host
resource "google_compute_address" "bastion_ip" {
  #depends_on  = [google_compute_network.vpc]
  name = "${var.environment_name}-bastion-ip"
}

# Create bastion Host VM Instance
resource "google_compute_instance" "bastion" {
  depends_on  = [google_compute_address.bastion_ip]
  name         = "${var.environment_name}-bastion-host"
  machine_type = var.bastion_machine_type
  zone         = "${var.region}-a" # Place in the first zone of the region

  # Attach the service account directly to the instance, however, instance-role not yet supported https://github.com/juju/juju/issues/20323
  service_account {
    email  = google_service_account.juju_controller.email
    scopes = ["cloud-platform"] # Allows full access to all cloud APIs, controlled by the IAM role
  }

  tags = ["bastion-host"]

  boot_disk {
    initialize_params {
      image = var.bastion_image
    }
  }

  network_interface {
    # Custom subnet not supported by juju https://github.com/juju/juju/issues/20321
    #subnetwork = google_compute_subnetwork.public.id
    network = "default"
    access_config {
      nat_ip = google_compute_address.bastion_ip.address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    # Pass the base64 encoded key as a metadata item
    gcp-sa-key = google_service_account_key.juju_controller_sa_key.private_key
    # The script will be run by root on instance startup
    startup-script = <<-EOT
      #!/bin/bash
      set -e # Exit immediately if a command exits with a non-zero status.

      # Define user variable for clarity
      TARGET_USER="${var.ssh_user}"
      KEY_FILE="/home/$${TARGET_USER}/gcp-key.json"

      # Get the key from metadata server
      # Note the escaped $$ for the shell variable SA_KEY_BASE64
      SA_KEY_BASE64=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcp-sa-key)

      # Decode and place the key in the user's home directory
      # THIS IS THE CORRECTED LINE:
      echo "$${SA_KEY_BASE64}" | base64 --decode > "$${KEY_FILE}"

      # Set correct ownership and permissions
      chown "$${TARGET_USER}":"$${TARGET_USER}" "$${KEY_FILE}"
      chmod 400 "$${KEY_FILE}"
    EOT
  }
}

# Reserve static IPs for the Coturn Load Balancer
resource "google_compute_address" "coturn_ips" {
  count = 3
  name  = "${var.environment_name}-coturn-lb-ip-${count.index + 1}"
}