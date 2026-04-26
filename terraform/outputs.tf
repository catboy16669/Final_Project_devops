output "ec2_public_ip" {
  value = aws_instance.aupp_lms_server.public_ip
}

output "website_url" {
  value = "http://${aws_instance.aupp_lms_server.public_ip}"
}

output "grafana_url" {
  value = "http://${aws_instance.aupp_lms_server.public_ip}:3000"
}

output "prometheus_url" {
  value = "http://${aws_instance.aupp_lms_server.public_ip}:9090"
}