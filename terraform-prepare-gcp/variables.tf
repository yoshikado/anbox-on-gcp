# variables.tf

variable "project_id" {
  description = "The Google Cloud project ID to deploy resources into."
  type        = string
}

variable "region" {
  description = "The Google Cloud region to deploy resources into."
  type        = string
  default     = "us-central1"
}

variable "vpc_name" {
  description = "vpc name"
  type        = string
  default     = "default"
}

variable "environment_name" {
  description = "An environment name that is prefixed to resource names."
  type        = string
  default     = "anbox-demo"
}

variable "public_subnet_cidr" {
  description = "The IP range (CIDR notation) for the public subnet."
  type        = string
  default     = "10.0.0.0/24"
}

variable "private_subnet_cidr" {
  description = "The IP range (CIDR notation) for the private subnet."
  type        = string
  default     = "10.146.0.0/20"
}

variable "private_domain_name" {
  description = "The private domain name (e.g., anbox.internal.) to be used for the private DNS zone. Must end with a period."
  type        = string
  default     = "anbox.internal."
}

variable "bastion_machine_type" {
  description = "The machine type for the bastion host."
  type        = string
  default     = "e2-medium"
}

variable "bastion_image" {
  description = "The image to be used for the bastion host."
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}

variable "ssh_public_key_path" {
  description = "The local path to the public SSH key that will be injected into the bastion host."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_user" {
  description = "The username associated with the public SSH key."
  type        = string
  default     = "ubuntu"
}

variable "juju_controller_iam_username" {
  description = "The name for the IAM service account for the Juju Controller."
  type        = string
  default     = "anbox-juju-controller"
}