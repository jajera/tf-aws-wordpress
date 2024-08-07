
resource "aws_iam_role" "size_monitor" {
  name = "${local.name}-size-monitor"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs_readonly" {
  role       = aws_iam_role.size_monitor.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "cw_fullaccess" {
  role       = aws_iam_role.size_monitor.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_policy" "efs_autoscaling" {
  name = "${local.name}-efs-autoscaling"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribePolicies",
          "autoscaling:UpdateAutoScalingGroup"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "${aws_s3_bucket.wordpress.arn}/*",
      }
    ]
  })
}

resource "aws_iam_policy" "efs_alarm_autoscaling" {
  name = "${local.name}-efs-alarm-autoscaling"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribePolicies",
          "autoscaling:UpdateAutoScalingGroup",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:PutMetricAlarm",
          "elasticfilesystem:DescribeFileSystems"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.efs_alarm.arn,
      }
    ]
  })
}

# resource "aws_iam_role" "bastion" {
#   name = "${local.name}-bastion"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

resource "aws_iam_policy" "bastion_autoscaling" {
  name = "${local.name}-bastion-autoscaling"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        "Resource" : [
          "arn:aws:logs:*:*:*"
        ],
        "Effect" : "Allow"
      }
    ]
  })
}

# resource "aws_iam_role_policy_attachment" "bastion" {
#   role       = aws_iam_role.bastion.name
#   policy_arn = aws_iam_policy.bastion.arn
# }

# resource "aws_iam_instance_profile" "bastion" {
#   name = "${local.name}-bastion"
#   role = aws_iam_role.bastion.name
# }
