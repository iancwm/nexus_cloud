output "instance_public_ip" {
  description = "Public IP of the Nexus workspace"
  value       = aws_instance.nexus_workspace.public_ip
}

output "instance_id" {
  description = "ID of the Nexus workspace instance"
  value       = aws_instance.nexus_workspace.id
}
