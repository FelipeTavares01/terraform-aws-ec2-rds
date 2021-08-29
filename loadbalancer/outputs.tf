# --- loadbalancer/outputs.tf

output "target_group_arn_out" {
  value = aws_lb_target_group.lb_target_group.arn
}

output "dns_loadbalancer_out" {
  value = aws_lb.loadbalancer.dns_name
}