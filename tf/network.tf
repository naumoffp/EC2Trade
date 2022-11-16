# data "aws_vpc" "default" {
#   default = true
# }

# data "aws_subnet" "default" {
#   availability_zone = var.trade_availability_zone
# }

# resource "aws_security_group" "trade_firewall" {
#   name   = "trade_sg"
#   vpc_id = data.aws_vpc.default.id

#   ingress {
#     description = "SSH"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = [var.client_ip]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "trade_efs_firewall" {
#   name   = "trade_efs_sg"
#   vpc_id = data.aws_vpc.default.id

#   ingress {
#     # NFSv4 runs on TCP port 2049. The NFS server must accept incoming connections on this port. Unlike previous versions of NFS, this is the only port that is required.
#     description     = "NFSv4"
#     from_port       = 2049
#     to_port         = 2049
#     protocol        = "tcp"
#     security_groups = [aws_security_group.trade_firewall.id]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_eip" "trade_ip" {
#   vpc = true
# }

# resource "aws_ssm_parameter" "trade_ip" {
#   name  = "trade_ip_allocation_id"
#   type  = "String"
#   value = aws_eip.trade_ip.allocation_id
# }

# resource "aws_ssm_parameter" "trade_availability_zone" {
#   name  = "trade_availability_zone"
#   type  = "String"
#   value = var.trade_availability_zone
# }
