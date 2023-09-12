# On-prem public IP addresses
resource "google_compute_address" "onprem-addresses" {
  count   = var.onprem_instance_count
  name    = "onpremclust0${count.index}"
  project = var.dev_proj_id
}

# On-prem instances
resource "google_compute_instance" "onprem-instances" {
  count          = var.onprem_instance_count
  name           = "onpremclust0${count.index}"
  machine_type   = var.onprem_instance_type
  zone           = var.gcp_zone_id
  desired_status = var.onprem_instance_status

  tags = ["http-server", "https-server", "allow-health-check"]

  boot_disk {
    initialize_params {
      image = var.onprem_image
      size  = var.onprem_disk_size
    }
    device_name = "onpremclust0${count.index}"
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.onprem-addresses[count.index].address
    }
  }

  metadata_startup_script = file("startup_script.sh")

}
