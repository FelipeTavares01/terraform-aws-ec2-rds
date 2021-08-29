# --- root/main.tf ---

module "networking" {
  source               = "./networking"
  vpc_cidr             = "10.0.0.0/16"
  access_ip            = var.access_ip
  security_groups      = local.security_groups
  public_subnet_count  = 2
  private_subnet_count = 3
  max_subnets          = 20
  public_cidrs         = [for i in range(2, 255, 2) : cidrsubnet("10.0.0.0/16", 8, i)]
  private_cidrs        = [for i in range(1, 255, 2) : cidrsubnet("10.0.0.0/16", 8, i)]
  db_subnet_group      = true
}

module "database" {
  source                 = "./database"
  db_storage             = 10
  db_engine_version      = "5.7.22"
  db_instance_class      = "db.t2.micro"
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password
  db_identifier          = "db-mysql"
  skip_final_snapshot    = true
  db_subnet_group_name   = module.networking.db_subnet_group_name_out[0]
  vpc_security_group_ids = module.networking.db_security_group_out

}

module "loadbalancer" {
  source                 = "./loadbalancer"
  public_subnets         = module.networking.public_subnets_out
  public_sg              = module.networking.public_security_group_out
  idle_timeout           = var.idle_timeout
  tg_port                = var.tg_port
  tg_protocol            = var.tg_protocol
  vpc_id                 = module.networking.vpc_id_out
  lb_healthy_threshold   = var.lb_healthy_threshold
  lb_unhealthy_threshold = var.lb_unhealthy_threshold
  lb_timeout             = var.lb_timeout
  lb_interval            = var.lb_interval
  listener_port          = var.listener_port
  listener_protocol      = var.listener_protocol
}

module "compute" {
  source              = "./compute"
  instance_count      = 2
  instance_type       = "t2.micro"
  public_sg           = module.networking.public_security_group_out
  public_subnets      = module.networking.public_subnets_out
  volume_size         = 20
  key_name            = "k8key"
  public_key_path     = "/home/ubuntu/.ssh/k8key.pub"
  user_data_path      = "${path.root}/userdata.tpl"
  dbuser              = var.db_username
  dbpass              = var.db_password
  db_endpoint         = module.database.db_endpoint_out
  dbname              = var.db_name
  lb_target_group_arn = module.loadbalancer.target_group_arn_out
  tg_attach_port      = var.tg_attach_port
  private_key_path    = "/home/ubuntu/.ssh/k8key"
}
 