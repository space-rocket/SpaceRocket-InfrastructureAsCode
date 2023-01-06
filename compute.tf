locals {
  ansible_vars = templatefile("./ansible-vars.json.tpl", {
    PHX_HOST = var.main_domain_name
    HOST     = var.main_domain_name
    PORT     = "8080"
    PHX_PORT = "8080"
    # DATABASE_URL = join("", ["ecto://", aws_db_instance.sre_db.username, ":", var.db_password, "@", aws_db_instance.sre_db.address, ":", aws_db_instance.sre_db.port, "/", var.db_name])
    DATABASE_URL = var.has_db ? "Yea" : "NO"
    GIT_URL      = var.git_url
  })
}

data "aws_ami" "server_ami" {
  most_recent = true

  owners = ["self"]

  filter {
    name   = "name"
    values = ["SpaceRocketUbuntuDockerAMI"]
  }
}

resource "random_id" "sre_node_id" {
  byte_length = 2
  count       = var.main_instance_count
}

resource "aws_key_pair" "sre_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# RDS DB
resource "aws_db_parameter_group" "sre_db_parameter_group" {
  count  = var.has_db ? 1 : 0
  name   = "sre-db-parameter-group"
  family = "postgres13"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "sre_db" {
  count                  = var.has_db ? 1 : 0
  identifier             = "sre-db"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "13.8"
  db_name                = var.db_name
  username               = var.db_user
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.sre_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sre_db_security_group.id]
  parameter_group_name   = var.has_db ? aws_db_parameter_group.sre_db_parameter_group[count.index].name : 0
  publicly_accessible    = true
  skip_final_snapshot    = true
}

# EC2
resource "aws_instance" "sre_main" {
  depends_on = []
  # depends_on             = [aws_db_instance.sre_db]
  count                  = var.main_instance_count
  instance_type          = var.main_instance_type
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.sre_auth.id
  vpc_security_group_ids = [aws_security_group.sre_app_sg.id]
  subnet_id              = aws_subnet.sre_public_subnet[count.index].id

  root_block_device {
    volume_size = var.main_vol_size
  }

  tags = {
    Name = "sre-main-${random_id.sre_node_id[count.index].dec}"
  }

  provisioner "local-exec" {
    command = "printf '\nubuntu@${self.public_ip}' >> hosts.txt && aws ec2 wait instance-status-ok --instance-ids ${self.id} --region ${var.region}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "sed -i '/^[a-z0-9@]/d' hosts.txt"
  }
}

resource "null_resource" "ssh" {
  count = var.main_instance_count
  provisioner "remote-exec" {
    inline = ["touch upgrade.log && echo 'I sshd in' >> upgrade.log"]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = aws_instance.sre_main[count.index].public_ip
    }
  }
}

resource "null_resource" "main-playbook" {

  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i hosts.txt --key-file /home/ubuntu/.ssh/devops_rsa playbooks/main-playbook.yml --extra-vars '${local.ansible_vars}'"
  }
  # triggers = {
  #   always_run = timestamp()
  # }
  depends_on = [null_resource.ssh]
}

# output "RDS-Endpoint" {
#   description = "RDS instance hostname"
#   value = var.has_db ? aws_db_instance.sre_db.endpoint : null
# }

# output "RDS_HOSTNAME" {
#   description = "RDS instance hostname"
#   value       = var.has_db ? aws_db_instance.sre_db.address : null
#   sensitive   = true
# }

# output "rds_port" {
#   description = "RDS instance port"
#   value       = var.has_db ? aws_db_instance.sre_db.port : null
# }

# output "rds_username" {
#   description = "RDS instance root username"
#   value       = var.has_db ? aws_db_instance.sre_db.username : null
# }

output "rds_password" {
  description = "RDS password"
  value       = var.has_db ? var.db_password : null
  sensitive   = true
}

output "rds_db_name" {
  description = "RDS DB Name"
  value       = var.has_db ? var.db_name : null
  sensitive   = true
}

output "instance_ips" {
  value = { for i in aws_instance.sre_main[*] : i.tags.Name => "${i.public_ip}" }
}
