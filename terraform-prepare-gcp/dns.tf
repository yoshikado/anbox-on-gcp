# dns.tf

# Private DNS Zone for internal resolution
#resource "google_dns_managed_zone" "private_zone" {
#  name        = "${var.environment_name}-private-zone"
#  dns_name    = var.private_domain_name
#  description = "Private DNS zone for the Anbox environment"
#  visibility  = "private"
#
#  private_visibility_config {
#    networks {
#      network_url = var.vpc_name
#    }
#  }
#}