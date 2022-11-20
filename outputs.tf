output "ip_address" {
  value       = aws_lightsail_static_ip_attachment.this.ip_address
  description = "The IP Address of the Lightsail instance."
}
