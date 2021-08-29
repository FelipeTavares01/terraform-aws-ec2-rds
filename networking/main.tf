# --- networking/main.tf ---

data "aws_availability_zones" "available" {}

resource "random_integer" "random" {
  min = 1
  max = 100
}

resource "random_shuffle" "az_list" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}

resource "aws_vpc" "myvpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "myvpc-${random_integer.random.id}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "my_public_subnet" {
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = random_shuffle.az_list.result[count.index]
  tags = {
    Name = "my_public_subnet-${count.index + 1}"
  }
}

resource "aws_route_table_association" "public_route_table_associate" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.my_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_subnet" "my_private_subnet" {
  count                   = var.private_subnet_count
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.private_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = random_shuffle.az_list.result[count.index]
  tags = {
    Name = "my_private_subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "my_internet_gateway"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "my_public_route_table"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_default_route_table" "private_route_table" {
  default_route_table_id = aws_vpc.myvpc.default_route_table_id
  tags = {
    Name = "private_route_table"
  }
}

resource "aws_security_group" "security_group" {
  for_each    = var.security_groups
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.myvpc.id
  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  count      = var.db_subnet_group == true ? 1 : 0
  name       = "rds_subnet_group"
  subnet_ids = aws_subnet.my_private_subnet.*.id
  tags = {
    Name = "rds_subnet_group"
  }
}


