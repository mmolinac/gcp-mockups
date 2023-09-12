# On-prem k8s cluster
output "onprem_public_ip_addresses" {
  description = "Public IP addresses of the on-prem cluster nodes"
  value       = [ for i in google_compute_address.onprem-addresses : i.address ]
}
