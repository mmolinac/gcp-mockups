variable "dev_proj_id" {
  description = "ID of development project on GCP"
  type        = string
}

variable "prod_proj_id" {
  description = "ID of production project on GCP"
  type        = string
}

variable "gcp_region_id" {
  description = "Default region for GCP assets"
  type        = string
}

variable "gcp_zone_id" {
  description = "Default zone for GCP assets"
  type        = string
}

variable "onprem_instance_count" {
  description = "Number of instances for the on-prem k8s cluster"
  type        = number
  default     = "3"
}

variable "onprem_instance_status" {
  description = "Status for GCE instances"
  type        = string
  default     = "RUNNING"
}

variable "onprem_instance_type" {
  description = "Machine type for on-prem k8s cluster nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "onprem_disk_size" {
  description = "Boot disk size for on-prem k8s cluster nodes"
  type        = number
  default     = "40"
}

# We can use any of the following, depending on our needs:
# - ubuntu-os-cloud/ubuntu-2004-lts
# - debian-cloud/debian-12
variable "onprem_image" {
  description = "OS image for on-prem k8s cluster nodes"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2004-lts"
}