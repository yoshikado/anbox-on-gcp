# iam.tf

# A service account for the Juju controller application
resource "google_service_account" "juju_controller" {
  account_id   = var.juju_controller_iam_username
  display_name = "Anbox Juju Controller Service Account"
}

# Commenting this out first to simplify the test
#resource "google_project_iam_custom_role" "juju_controller_role" {
#  role_id     = "anboxJujuController"
#  title       = "Anbox Juju Controller Role"
#  description = "Permissions for the Anbox Juju controller to manage GCP resources"
#  permissions = [
#    "compute.images.list",
#    "compute.instances.attachDisk",
#    "compute.instances.detachDisk",
#    "compute.instances.create",
#    "compute.instances.delete",
#    "compute.instances.get",
#    "compute.instances.list",
#    "compute.instances.setTags",
#    "compute.instances.setMetadata",
#    "compute.instances.setServiceAccount",
#    "compute.disks.create",
#    "compute.disks.delete",
#    "compute.disks.get",
#    "compute.disks.list",
#    "compute.disks.setLabels",
#    "compute.disks.use",
#    "compute.firewalls.create",
#    "compute.firewalls.delete",
#    "compute.firewalls.list",
#    "compute.machineTypes.list",
#    "compute.projects.get",
#    "compute.subnetworks.list",
#    "compute.subnetworks.use",
#    "compute.subnetworks.useExternalIp",
#    "compute.networks.list",
#    "compute.networks.use",
#    "compute.networks.updatePolicy",
#    "compute.zones.get",
#    "compute.zones.list",
#    "compute.zoneOperations.get",
#    "storage.buckets.get",
#    "storage.buckets.list",
#    "storage.objects.create",
#    "storage.objects.delete",
#    "storage.objects.get",
#    "storage.objects.list"
#  ]
#}

# Bind the custom role to the service account
resource "google_project_iam_member" "juju_binding" {
  project = var.project_id
  #role    = google_project_iam_custom_role.juju_controller_role.id # Commenting this out first to simplify the test
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.juju_controller.email}"
}

resource "google_service_account_key" "juju_controller_sa_key" {
  service_account_id = google_service_account.juju_controller.name
}
