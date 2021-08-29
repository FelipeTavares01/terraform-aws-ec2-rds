# --- compute/main.tf ---

data "aws_ami" "server_ami" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

resource "random_id" "node_kubernetes_id" {
  byte_length = 2
  count       = var.instance_count
  keepers = {
    key_name = var.key_name
  }
}

resource "aws_key_pair" "keypair" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "node_kubernetes" {
  count                  = var.instance_count
  instance_type          = var.instance_type
  ami                    = data.aws_ami.server_ami.id
  vpc_security_group_ids = [var.public_sg]
  subnet_id              = var.public_subnets[count.index]
  key_name               = aws_key_pair.keypair.id
  user_data = templatefile(var.user_data_path,
    {
      nodename    = "node-kubernetes-${random_id.node_kubernetes_id[count.index].dec}"
      dbuser      = var.dbuser
      dbpass      = var.dbpass
      db_endpoint = var.db_endpoint
      dbname      = var.dbname
    }
  )
  root_block_device {
    volume_size = var.volume_size
  }
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = self.public_ip
      private_key = file(var.private_key_path)
    }
    script = "${path.cwd}/delay.sh"
  }
  provisioner "local-exec" {
    command = templatefile("${path.cwd}/scp_script.tpl",
      {
        nodeip   = self.public_ip
        k3s_path = "${path.cwd}/../"
        nodename = self.tags.Name
        private_key_path = var.private_key_path
      }
    )
  }
  provisioner "local-exec" {
    when = destroy
    command = "rm -f ${path.cwd}/../k3s-${self.tags.Name}.yaml"
  }
  tags = {
    Name = "node-kubernetes-${random_id.node_kubernetes_id[count.index].dec}"
  }
}

resource "aws_lb_target_group_attachment" "tg_attach" {
  count            = var.instance_count
  target_group_arn = var.lb_target_group_arn
  target_id        = aws_instance.node_kubernetes[count.index].id
  port             = var.tg_attach_port
}

