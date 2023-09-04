# On-prem k8s cluster
output "onprem_global_fwd_rule_ip" {
    description = "IP address of the on-prem Kubernetes cluster's load balancer"
    value = google_compute_global_forwarding_rule.onprem-fwd-rule.ip_address
}
