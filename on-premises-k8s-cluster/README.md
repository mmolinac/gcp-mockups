# On-premises Kubernetes cluster
In this mockup we'll spawn three servers of `e2-standard-2` type.

This will be an unmanaged instance group and we'll add a metadata script to perform these initial ations:
- Add the official Kubernetes repository and install the basic packages
- Create the unmanaged instance group
- Create a load balancer on top of these instance, if needed, for ports tcp/80 and tcp/443 .

Additional features:
- You'll have the tools to create, manage and maintain the on-premises cluster.
- The cluster *won't* be built. You have to do it.

## Initialize stack
To start using this mockup, please do this once:
```Shell
$ init.sh
Initializing the backend...

Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Finding hashicorp/google versions matching "~> 4.80.0"...
- Installing hashicorp/google v4.80.0...
- Installed hashicorp/google v4.80.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

## Start stack
To create or turn on the stack, you have to:

```Shell
$ ./apply.sh 
Reading required version from terraform file
Reading required version from constraint: >= 1.4
Matched version: 1.5.6
Switched terraform to version "1.5.6" 

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following
symbols:
  + create
...
...
```
Just answer `yes` when asked to.

## Log in to compute hosts
We'll log in through:
```Shell
$ gcloud compute ssh onpremclust00
WARNING: The private SSH key file for gcloud does not exist.
WARNING: The public SSH key file for gcloud does not exist.
WARNING: You do not have an SSH key for gcloud.
WARNING: SSH keygen will be executed to generate a key.
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
...
...
```
And off you go.

## Turn off hosts
When you're not using them, you can just turn them off temporarily by doing:
```Shell
$ ./apply.sh off
...
```
It will stop the hosts, so the compute expense will be zero.

## Destroy the stack
You have to issue this:
```Shell
$ ./destroy.sh 
Reading required version from terraform file
Reading required version from constraint: >= 1.4
Matched version: 1.5.6
Switched terraform to version "1.5.6" 
...
...

Plan: 0 to add, 0 to change, 6 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: 
```
Enter `yes` and that will be all.

# Additions
If you like, you can add the following to also create a Google Cloud load balancer.
See the files to add below:

## loadbalancer.tf
```terraform
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
```

## outputs.tf
```terraform
output "onprem_global_fwd_rule_ip" {
  description = "IP address of the on-prem Kubernetes cluster's load balancer"
  value       = google_compute_global_forwarding_rule.onprem-fwd-rule.ip_address
}
```
