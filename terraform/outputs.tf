# ═══════════════════════════════════════════════════════════════
# OUTPUTS
# These values are printed after terraform apply
# and used by GitHub Actions to deploy to the right servers
# ═══════════════════════════════════════════════════════════════

# ── App Server ────────────────────────────────────────────────
output "app_server_ip" {
  description = "Public IP of the App server"
  value       = aws_instance.app_server.public_ip
}

output "website_url" {
  description = "AUPP LMS website URL"
  value       = "http://${aws_instance.app_server.public_ip}"
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${aws_instance.app_server.public_ip}:3000"
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://${aws_instance.app_server.public_ip}:9090"
}

# ── AMI Used ─────────────────────────────────────────────────
output "ami_used" {
  description = "Ubuntu AMI that was selected automatically"
  value       = data.aws_ami.ubuntu.id
}

# ── Summary ───────────────────────────────────────────────────
output "summary" {
  description = "Quick access to all services"
  value = <<-EOT

  ╔══════════════════════════════════════════════════════════╗
  ║           AUPP LMS Infrastructure Ready                 ║
  ╠══════════════════════════════════════════════════════════╣
  ║  🌐 Website:     http://${aws_instance.app_server.public_ip}           ║
  ║  📊 Prometheus:  http://${aws_instance.app_server.public_ip}:9090      ║
  ║  📈 Grafana:     http://${aws_instance.app_server.public_ip}:3000      ║
  ║     Grafana login: admin / admin123                      ║
  ╚══════════════════════════════════════════════════════════╝

  EOT
}
