# main.tf

provider "google" {
  project = var.project_id
  region  = var.region
}

# A global VPC Network, equivalent to AWS VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.environment_name}-vpc"
  auto_create_subnetworks = false # We want custom subnets
}

# A regional subnet for "public" resources
resource "google_compute_subnetwork" "public" {
  name          = "${var.environment_name}-public-subnet"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

# A regional subnet for "private" resources
resource "google_compute_subnetwork" "private" {
  name          = "${var.environment_name}-private-subnet"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  private_ip_google_access = true
}

# A Cloud Router is required for Cloud NAT
resource "google_compute_router" "router" {
  name    = "${var.environment_name}-router"
  network = google_compute_network.vpc.id
  region  = var.region
}

# Managed NAT Gateway for the private subnet, replacing the 3 AWS NAT Gateways
resource "google_compute_router_nat" "nat" {
  name                               = "${var.environment_name}-nat-gateway"
  router                             = google_compute_router.router.name
  region                             = var.region
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# Firewall rule to allow SSH to the bastion host, equivalent to the JumpboxSecurityGroup
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.environment_name}-allow-ssh"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion-host"]
}

# Static IP for the Bastion Host
resource "google_compute_address" "bastion_ip" {
  name = "${var.environment_name}-bastion-ip"
}

# Bastion Host VM Instance, equivalent to the Jumpbox
resource "google_compute_instance" "bastion" {
  name         = "${var.environment_name}-bastion-host"
  machine_type = var.bastion_machine_type
  zone         = "${var.region}-a" # Place in the first zone of the region

  tags = ["bastion-host"]

  boot_disk {
    initialize_params {
      image = var.bastion_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public.id
    access_config {
      nat_ip = google_compute_address.bastion_ip.address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

# Reserve static IPs for the Coturn Load Balancer, equivalent to CoturnLoadBalancerEIPs
resource "google_compute_address" "coturn_ips" {
  count = 3
  name  = "${var.environment_name}-coturn-lb-ip-${count.index + 1}"
}