# --- compute/outputs.tf ---

output "instances_out" {
  value     = aws_instance.node_kubernetes[*]
  sensitive = true
}

output "instance_port_out" {
  value = aws_lb_target_group_attachment.tg_attach[0].port
}