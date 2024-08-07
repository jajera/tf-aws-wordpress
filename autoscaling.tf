module "autoscaling_efs" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.7.0"

  # Autoscaling group
  name                      = "${local.name}-efs"
  default_cooldown          = 60
  default_instance_warmup   = 0
  desired_capacity          = 1
  health_check_grace_period = 120
  health_check_type         = "EC2"
  max_size                  = 1
  min_size                  = 0
  vpc_zone_identifier       = module.vpc.database_subnets
  wait_for_capacity_timeout = "0"

  scaling_policies = {
    scale_up = {
      name               = "${local.name}-scale-up"
      adjustment_type    = "ChangeInCapacity"
      scaling_adjustment = 1
      cooldown           = 60
      policy_type        = "SimpleScaling"
    }
  }

  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = "${local.name}-efs"
  iam_role_path               = "/ec2/"
  iam_role_description        = "EFS EC2 instance profile"

  iam_role_tags = {
    CustomIamRole = "Yes"
  }

  iam_role_policies = {
    "${local.name}-efs-autoscaling" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.name}-efs-autoscaling"
  }

  # Launch template
  launch_template_description = "Launch template for efs"
  launch_template_name        = "${local.name}-efs"

  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_name = "${local.name}-efs"
  instance_type = "r4.large"

  user_data = base64encode(templatefile("${path.module}/external/efs.sh.tpl", {
    COPY_SYSTEM_ID = aws_sns_topic.efs_alarm.arn
    DATA_DIRECTORY = aws_cloudwatch_metric_alarm.efs_burst_credit_balance_warning.threshold
    FILE_SYSTEM_ID = module.efs.id
    GROWTH         = aws_cloudwatch_metric_alarm.efs_burst_credit_balance_critical.threshold
    S3_BUCKET      = aws_s3_bucket.wordpress.bucket
    WP_DIR         = aws_sns_topic.efs_alarm.arn
  }))

  # TODO - define key_name

  network_interfaces = [
    {
      associate_public_ip_address = false
      delete_on_termination       = true
      description                 = "eth0"
      device_index                = 0

      security_groups = [
        aws_security_group.efs.id
      ]
    }
  ]
}

module "autoscaling_efs_alarm" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.7.0"

  # Autoscaling group
  name                      = "${local.name}-efs-alarm"
  default_cooldown          = 60
  default_instance_warmup   = 0
  desired_capacity          = 1
  health_check_grace_period = 120
  health_check_type         = "EC2"
  max_size                  = 1
  min_size                  = 0
  vpc_zone_identifier       = module.vpc.database_subnets
  wait_for_capacity_timeout = "0"

  scaling_policies = {
    scale = {
      name               = "${local.name}-scale"
      adjustment_type    = "ChangeInCapacity"
      scaling_adjustment = 1
      cooldown           = 60
      policy_type        = "SimpleScaling"
    }
  }

  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = "${local.name}-efs-alarm"
  iam_role_path               = "/ec2/"
  iam_role_description        = "EFS alarm EC2 instance profile"

  iam_role_tags = {
    CustomIamRole = "Yes"
  }

  iam_role_policies = {
    "${local.name}-efs-alarm-autoscaling" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.name}-efs-alarm-autoscaling"
  }

  # Launch template
  launch_template_description = "Launch template for efs alarm"
  launch_template_name        = "${local.name}-efs-alarm"

  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_name = "${local.name}-efs-alarm"
  instance_type = "t3.nano"

  user_data = base64encode(templatefile("${path.module}/external/efs_alarm.sh.tpl", {
    CRITICAL_THRESHOLD_MINUTES = aws_cloudwatch_metric_alarm.efs_burst_credit_balance_critical.threshold
    FILE_SYSTEM_ID             = module.efs.id
    S3_BUCKET                  = aws_s3_bucket.wordpress.bucket
    SNS_ARN                    = aws_sns_topic.efs_alarm.arn
    WARNING_THRESHOLD_MINUTES  = aws_cloudwatch_metric_alarm.efs_burst_credit_balance_warning.threshold
  }))

  # TODO - define key_name

  network_interfaces = [
    {
      associate_public_ip_address = false
      delete_on_termination       = true
      description                 = "eth0"
      device_index                = 0

      security_groups = [
        aws_security_group.efs.id
      ]
    }
  ]

  tags = {
    key                 = "Name"
    value               = "Updating ${module.efs.id} burst credit balance Cloudwatch alarms.. will auto terminate"
    propagate_at_launch = true
  }
}

# TODO - delete extra permission AWS-QuickSetup-StackSet-Local-AdministrationRole

module "autoscaling_bastion" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.7.0"

  # Autoscaling group
  name                      = "${local.name}-bastion"
  default_cooldown          = 60
  default_instance_warmup   = 0
  desired_capacity          = 1
  health_check_grace_period = 120
  health_check_type         = "EC2"
  max_size                  = 1
  min_size                  = 0
  vpc_zone_identifier       = module.vpc.private_subnets
  wait_for_capacity_timeout = "0"

  scaling_policies = {
    scale = {
      name               = "${local.name}-scale"
      adjustment_type    = "ChangeInCapacity"
      scaling_adjustment = 1
      cooldown           = 60
      policy_type        = "SimpleScaling"
    }
  }

  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = "${local.name}-bastion"
  iam_role_path               = "/ec2/"
  iam_role_description        = "Bastion EC2 instance profile"

  iam_role_tags = {
    CustomIamRole = "Yes"
  }

  iam_role_policies = {
    "${local.name}-bastion-autoscaling" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.name}-bastion-autoscaling"
  }

  # Launch template
  launch_template_description = "Launch template for bastion"
  launch_template_name        = "${local.name}-bastion"

  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_name = "${local.name}-bastion"
  instance_type = "t3.nano"

  # TODO - define key_name

  network_interfaces = [
    {
      associate_public_ip_address = false
      delete_on_termination       = true
      description                 = "eth0"
      device_index                = 0

      security_groups = [
        aws_security_group.bastion.id
      ]
    }
  ]

  tags = {
    key                 = "Name"
    value               = "bastion"
    propagate_at_launch = true
  }
}
