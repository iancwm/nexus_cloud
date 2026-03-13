output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.coder.dns_name
}

output "coder_url" {
  description = "The public URL of the Coder server"
  value       = "https://${var.domain_name}"
}

output "instance_id" {
  description = "The ID of the Coder server EC2 instance"
  value       = aws_instance.coder_server.id
}
