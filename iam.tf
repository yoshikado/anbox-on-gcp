# iam.tf

# A service account for the Juju controller application
resource "google_service_account" "juju_controller" {
  account_id   = var.juju_controller_iam_username
  display_name = "Anbox Juju Controller Service Account"
}

# A custom IAM role with permissions equivalent to the AWS Policy.
# Note: The original AWS policy is complex and uses AWS-specific conditions (ec2:ResourceTag)
# that do not translate 1:1. This role grants broader, but functionally similar, permissions
# for managing compute and storage resources, which is the standard practice in GCP.
resource "google_project_iam_custom_role" "juju_controller_role" {
  role_id     = "anboxJujuController"
  title       = "Anbox Juju Controller Role"
  description = "Permissions for the Anbox Juju controller to manage GCP resources"
  permissions = [
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.setTags",
    "compute.instances.setMetadata",
    "compute.instances.setServiceAccount",
    "compute.disks.create",
    "compute.disks.delete",
    "compute.disks.get",
    "compute.disks.list",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
    "compute.networks.use",
    "compute.zones.get",
    "compute.zones.list",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list"
  ]
}

# Bind the custom role to the service account
resource "google_project_iam_member" "juju_binding" {
  project = var.project_id
  role    = google_project_iam_custom_role.juju_controller_role.id
  member  = "serviceAccount:${google_service_account.juju_controller.email}"
}