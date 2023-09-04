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

# Google Compute Backend service
resource "google_compute_network_endpoint" "onprem-endpoint" {
  count                  = var.onprem_instance_count
  network_endpoint_group = google_compute_network_endpoint_group.onprem-neg.name
  instance               = google_compute_instance.onprem-instances[count.index].name
  port                   = google_compute_network_endpoint_group.onprem-neg.default_port
  ip_address             = google_compute_instance.onprem-instances[count.index].network_interface[0].network_ip
}

resource "google_compute_network_endpoint_group" "onprem-neg" {
  name         = "onprem-lb-neg"
  network      = "default"
  subnetwork   = "default"
  default_port = "80"
  zone         = var.gcp_zone_id
}

resource "google_compute_backend_service" "onpremclust-backend" {
  name          = "onprem-be"
  health_checks = [google_compute_health_check.onprem-hc.id]
  backend {
    group          = google_compute_network_endpoint_group.onprem-neg.id
    balancing_mode = "RATE"
    max_rate       = 100
  }
}

resource "google_compute_health_check" "onprem-hc" {
  name               = "onprem-hc"
  timeout_sec        = 5
  check_interval_sec = 5
  http_health_check {
    port = 80
  }
}

resource "google_compute_global_forwarding_rule" "onprem-fwd-rule" {
  name       = "onprem-fwd-rule"
  target     = google_compute_target_http_proxy.onprem-http-proxy.id
  port_range = "80"
}

resource "google_compute_target_http_proxy" "onprem-http-proxy" {
  name    = "onprem-proxy"
  url_map = google_compute_url_map.onprem-url-map.id
}

resource "google_compute_url_map" "onprem-url-map" {
  name            = "omprem-url-map"
  default_service = google_compute_backend_service.onpremclust-backend.id
}

# Firewall rules
# allow access from health check ranges
resource "google_compute_firewall" "default" {
  name          = "onprem-fw-allow-hc"
  direction     = "INGRESS"
  network       = "default"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  allow {
    protocol = "tcp"
  }
  target_tags = ["allow-health-check"]
}
