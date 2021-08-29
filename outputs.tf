# ---root/output.tf

output "loadbalancer_endpoint" {
  value = module.loadbalancer.dns_loadbalancer_out
}

output "instances" {
  value     = { for i in module.compute.instances_out : i.tags.Name => "${i.public_ip}:${module.compute.instance_port_out}" }
  sensitive = true
}

output "kubeconfig" {
  value = [for i in module.compute.instances_out : "export KUBECONFIG=../k3s-${i.tags.Name}.yaml"]
  sensitive = true
}