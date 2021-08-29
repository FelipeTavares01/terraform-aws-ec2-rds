# --- root/variable.tf ---

variable "aws_region" {
  default = "us-east-1"
}

variable "access_ip" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "tg_port" {
  type = number
}

variable "tg_protocol" {
  type = string
}

variable "lb_healthy_threshold" {
  type = number
}

variable "lb_unhealthy_threshold" {
  type = number
}

variable "lb_timeout" {
  type = number
}

variable "lb_interval" {
  type = number
}

variable "idle_timeout" {
  type = number
}

variable "listener_port" {
  type = string
}

variable "listener_protocol" {
  type = string
}

variable "tg_attach_port" {
  type = number
}