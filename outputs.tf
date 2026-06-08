output "app_url" {
  description = "Mo tren browser (doi ~2-3 phut cho app len)"
  value       = "http://${aws_lb.this.dns_name}"
}

output "ec2_public_ip" {
  value = aws_instance.node.public_ip
}

output "ec2_instance_id" {
  description = "Dung de stop/start tiet kiem tien"
  value       = aws_instance.node.id
}

output "target_group_arn" {
  value = aws_lb_target_group.this.arn
}

output "ssh_command" {
  value = "ssh -i ${var.name}-key.pem ubuntu@${aws_instance.node.public_ip}"
}
