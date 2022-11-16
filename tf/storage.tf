# resource "aws_efs_file_system" "trade_efs" {
#   availability_zone_name = var.trade_availability_zone
#   creation_token         = "trade_files"

#   lifecycle_policy {
#     transition_to_ia = "AFTER_7_DAYS"
#   }

#   lifecycle_policy {
#     transition_to_primary_storage_class = "AFTER_1_ACCESS"
#   }

#   lifecycle {
#     prevent_destroy = false
#   }
# }

# # TODO: Make access points configurable
# resource "aws_efs_access_point" "trade_efs_trade_ap" {
#   file_system_id = aws_efs_file_system.trade_efs.id
#   posix_user {
#     uid = 1000
#     gid = 1000
#   }

#   root_directory {
#     creation_info {
#       owner_uid   = 1000
#       owner_gid   = 1000
#       permissions = 0755
#     }
#     path = "/ec2trade"
#   }
# }

# resource "aws_efs_access_point" "trade_efs_docker_ap" {
#   file_system_id = aws_efs_file_system.trade_efs.id
#   posix_user {
#     uid = 0
#     gid = 0
#   }

#   root_directory {
#     creation_info {
#       owner_uid   = 0
#       owner_gid   = 0
#       permissions = 0755
#     }
#     path = "/docker"
#   }
# }

# resource "aws_efs_mount_target" "trade_efs_mount" {
#   file_system_id  = aws_efs_file_system.trade_efs.id
#   subnet_id       = data.aws_subnet.default.id
#   security_groups = [aws_security_group.trade_efs_firewall.id]
# }

# resource "aws_ssm_parameter" "trade_efs" {
#   name  = "trade_efs_id"
#   type  = "String"
#   value = aws_efs_file_system.trade_efs.id
# }

# resource "aws_ssm_parameter" "trade_efs_trade_ap" {
#   name  = "trade_efs_ec2trade_ap"
#   type  = "String"
#   value = aws_efs_access_point.trade_efs_trade_ap.id
# }

# resource "aws_ssm_parameter" "trade_efs_docker_ap" {
#   name  = "trade_efs_docker_AP"
#   type  = "String"
#   value = aws_efs_access_point.trade_efs_docker_ap.id
# }
