terraform {
  required_version = ">= 1.4, <= 1.5.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.80.0"
    }
  }
  backend "gcs" {
  }
}

provider "google" {
  project = var.dev_proj_id
  region  = var.gcp_region_id
  zone    = var.gcp_zone_id
}
