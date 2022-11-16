data "aws_caller_identity" "current" {}

resource "aws_iam_role" "trade_spot_fleet_role" {
  name = "EC2Trade_spot_fleet_role-${random_string.random.result}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "spotfleet.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "trade_spot_fleet"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action : [
            "ec2:DescribeImages",
            "ec2:DescribeSubnets",
            "ec2:RequestSpotInstances",
            "ec2:TerminateInstances",
            "ec2:DescribeInstanceStatus",
            "ec2:CreateTags",
            "ec2:RunInstances"
          ],
          Resource = "*"
        },
        {
          Effect = "Allow",
          Action = "iam:PassRole",
          Condition = {
            StringEquals = {
              "iam:PassedToService" = [
                "ec2.amazonaws.com",
                "ec2.amazonaws.com.cn"
              ]
            }
          },
          Resource = "*"
        },
        {
          Effect   = "Allow",
          Action   = "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          Resource = "arn:aws:elasticloadbalancing:*:*:loadbalancer/*"
        },
        {
          Effect   = "Allow",
          Action   = "elasticloadbalancing:RegisterTargets",
          Resource = "arn:aws:elasticloadbalancing:*:*:*/*"
        }
      ]
    })
  }
}

resource "aws_iam_role" "trade_instance_role" {
  name = "EC2Trade_instance_role-${random_string.random.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.arn
        }
      }
    ]
  })

  # S3 Policy
  inline_policy {
    name = "trade_s3_bucket"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "s3:ListBucket",
            "s3:CreateBucket",
            "s3:DeleteBucket"
          ]
          Resource = "arn:aws:s3:::${var.trade_storage_bucket}"
        },
        {
          Effect = "Allow",
          Action = [
            "s3:*",
            "s3-object-lambda:*"
          ]
          Resource = "arn:aws:s3:::${var.trade_storage_bucket}/*"
        }
      ]
    })
  }

  # SSM Policy
  inline_policy {
    name = "trade_ssm_access"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "ssm:PutParameter",
            "ssm:DeleteParameter",
            "ssm:GetParameterHistory",
            "ssm:GetParametersByPath",
            "ssm:GetParameters",
            "ssm:GetParameter",
            "ssm:DeleteParameters"
          ]
          Resource = "arn:aws:ssm:${var.trade_region}:${data.aws_caller_identity.current.account_id}:parameter/trade_*"
        },
        {
          Effect = "Allow",
          Action = [
            "ssm:DescribeParameters"
          ]
          Resource = "*"
        }
      ]
    })
  }

  # EC2/Elastic IP Policy
  inline_policy {
    name = "trade_ec2_access"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ec2:AssociateAddress"
          ]
          Resource = [
            "arn:aws:ec2:${var.trade_region}:${data.aws_caller_identity.current.account_id}:instance/*",
            "arn:aws:ec2:${var.trade_region}:${data.aws_caller_identity.current.account_id}:elastic-ip/${aws_eip.trade_ip.allocation_id}"
          ]
        }
      ]
    })
  }

}

# Role to access all AWS Services
resource "aws_iam_role" "trade_admin_role" {
  name = "EC2Trade_admin_role-${random_string.random.result}"

  # admin
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.arn
        }
      }
    ]
  })

  inline_policy {
    name = "trade_admin_access"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow",
          Action   = "*"
          Resource = "*"
        }
      ]
    })
  }
}
