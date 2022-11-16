output "EC2Trade_info" {
  value = {
    vpc_id              = data.aws_vpc.default.id
    public_ipv4         = aws_eip.trade_ip.public_ip
    efs_id              = aws_efs_file_system.trade_efs.id
    access_point_data   = aws_efs_access_point.trade_efs_trade_ap.id
    access_point_docker = aws_efs_access_point.trade_efs_docker_ap.id
    ssh_access          = "ssh ec2trade-user@${aws_eip.trade_ip.public_ip}"
    bucket_name         = aws_s3_bucket.trade_bucket.bucket
  }
}

output "ip_to_connect" {
  value = aws_eip.trade_ip.public_ip
}
output "roles" {
  value = {
    spot_fleet_role = aws_iam_role.trade_spot_fleet_role.arn,
    ec2_iam_role    = aws_iam_role.trade_instance_role.arn,
    admin_role      = aws_iam_role.trade_admin_role.arn
  }
}

output "efs_mount" {
  value = {
    home   = "sudo mount -t efs -o az=${var.trade_availability_zone},tls,accesspoint=${aws_efs_access_point.trade_efs_trade_ap.id} ${aws_efs_file_system.trade_efs.id}:/ /ec2trade"
    docker = "sudo mount -t efs -o az=${var.trade_availability_zone},tls,accesspoint=${aws_efs_access_point.trade_efs_docker_ap.id} ${aws_efs_file_system.trade_efs.id}:/ /docker"
  }
}
