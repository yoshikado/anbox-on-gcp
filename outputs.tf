# outputs.tf

output "vpc_network_name" {
  description = "The name of the created VPC network."
  value       = google_compute_network.vpc.name
}

output "public_subnet_name" {
  description = "The name of the public subnet."
  value       = google_compute_subnetwork.public.name
}

output "private_subnet_name" {
  description = "The name of the private subnet."
  value       = google_compute_subnetwork.private.name
}

output "bastion_host_public_ip" {
  description = "The public IP address of the bastion host."
  value       = google_compute_address.bastion_ip.address
}

output "private_dns_zone_name" {
  description = "The name of the private DNS managed zone."
  value       = google_dns_managed_zone.private_zone.name
}

output "juju_controller_service_account_email" {
  description = "The email of the service account for the Juju controller."
  value       = google_service_account.juju_controller.email
}

output "coturn_load_balancer_ips" {
  description = "List of static IPs reserved for the Coturn service."
  value       = google_compute_address.coturn_ips[*].address
}