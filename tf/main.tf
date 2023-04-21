terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # upgrade to 4.29.0
      version = "3.73.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = var.trade_region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  availability_zone = var.trade_availability_zone
}

resource "random_string" "random" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

resource "aws_security_group" "trade_firewall" {
  name   = "trade_sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.client_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "trade_efs_firewall" {
  name   = "trade_efs_sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    # NFSv4 runs on TCP port 2049. The NFS server must accept incoming connections on this port. Unlike previous versions of NFS, this is the only port that is required.
    description     = "NFSv4"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.trade_firewall.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_file_system" "trade_efs" {
  availability_zone_name = var.trade_availability_zone
  creation_token         = "trade_files"

  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# TODO: Make access points configurable
resource "aws_efs_access_point" "trade_efs_trade_ap" {
  file_system_id = aws_efs_file_system.trade_efs.id
  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = 0755
    }
    path = "/ec2trade"
  }
}

resource "aws_efs_access_point" "trade_efs_docker_ap" {
  file_system_id = aws_efs_file_system.trade_efs.id
  posix_user {
    uid = 0
    gid = 0
  }

  root_directory {
    creation_info {
      owner_uid   = 0
      owner_gid   = 0
      permissions = 0755
    }
    path = "/docker"
  }
}

resource "aws_efs_mount_target" "trade_efs_mount" {
  file_system_id  = aws_efs_file_system.trade_efs.id
  subnet_id       = data.aws_subnet.default.id
  security_groups = [aws_security_group.trade_efs_firewall.id]
}

resource "aws_eip" "trade_ip" {
  vpc = true
}

resource "aws_ssm_parameter" "trade_ip" {
  name  = "trade_ip_allocation_id"
  type  = "String"
  value = aws_eip.trade_ip.allocation_id
}

# EFS availability zome
resource "aws_ssm_parameter" "trade_availability_zone" {
  name  = "trade_availability_zone"
  type  = "String"
  value = var.trade_availability_zone
}

resource "aws_ssm_parameter" "trade_efs" {
  name  = "trade_efs_id"
  type  = "String"
  value = aws_efs_file_system.trade_efs.id
}

resource "aws_ssm_parameter" "trade_efs_trade_ap" {
  name  = "trade_efs_trade_ap"
  type  = "String"
  value = aws_efs_access_point.trade_efs_trade_ap.id
}

resource "aws_ssm_parameter" "trade_efs_docker_ap" {
  name  = "trade_efs_docker_ap"
  type  = "String"
  value = aws_efs_access_point.trade_efs_docker_ap.id
}

resource "aws_ssm_parameter" "trade_ssh_key" {
  name  = "trade_ssh_key"
  type  = "String"
  value = var.trade_ssh_public_key
}

# This is where the amazon machine image is defined
# TODO: Make this configurable
data "aws_ami" "trade_os" {

  owners = ["amazon"]
  most_recent = "true"

  filter {
    name = "name"
    values = [ "amzn2-ami-kernel-*" ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # owners = ["amazon"]
  # most_recent = "true"
  # # arn "ami-0db84aebfa8d17e23"

  # filter {
  #   name = "name"
  #   values = [ "ubuntu/images/hvm-ssd/ubuntu-jammy-*" ]
  # }

  # filter {
  #   name = "architecture"
  #   values = ["x86_64"]
  # }

  # filter {
  #   name   = "virtualization-type"
  #   values = ["hvm"]
  # }
}

resource "aws_iam_instance_profile" "trade_ec2_profile" {
  name = "EC2Trade_profile-${random_string.random.result}"
  role = aws_iam_role.trade_instance_role.name
}

resource "aws_key_pair" "trade_ssh_key" {
  key_name   = "trade_ssh_key"
  public_key = var.trade_ssh_public_key
}

resource "aws_spot_fleet_request" "trade_spot_request" {
  iam_fleet_role                      = aws_iam_role.trade_spot_fleet_role.arn
  spot_price                          = var.trade_price
  allocation_strategy                 = "diversified"
  target_capacity                     = 1
  fleet_type                          = "maintain"
  on_demand_target_capacity           = 0
  instance_interruption_behaviour     = "terminate"
  terminate_instances_with_expiration = true
  wait_for_fulfillment                = true
  depends_on = [
    aws_efs_file_system.trade_efs,
    aws_efs_mount_target.trade_efs_mount,
    aws_efs_access_point.trade_efs_trade_ap,
    aws_efs_access_point.trade_efs_docker_ap
  ]

  launch_specification {
    key_name               = aws_key_pair.trade_ssh_key.id
    instance_type          = var.trade_instance_type
    ami                    = data.aws_ami.trade_os.id
    spot_price             = var.trade_price
    iam_instance_profile   = aws_iam_instance_profile.trade_ec2_profile.name
    vpc_security_group_ids = [aws_security_group.trade_firewall.id]
    availability_zone        = var.trade_availability_zone

    user_data = <<EOF
#!/bin/sh

curl -L -s ${var.trade_install_script} | bash
EOF
  }
}

resource "aws_s3_bucket" "trade_bucket" {
  bucket = var.trade_storage_bucket != "" ? var.trade_storage_bucket : lower("ec2trade-bucket-${random_string.random.result}")
  acl    = "private"
}
