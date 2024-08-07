
resource "aws_cloudwatch_event_rule" "size_monitor" {
  name                = "${local.name}-size-monitor"
  schedule_expression = "cron(0/1 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "size_monitor" {
  rule      = aws_cloudwatch_event_rule.size_monitor.name
  target_id = "lambda"
  arn       = aws_lambda_function.size_monitor.arn
}

resource "aws_cloudwatch_metric_alarm" "efs_burst_credit_balance_warning" {
  alarm_name        = "${local.name}-efs-burst-credit-balance-warning"
  alarm_description = "${module.efs.id} burst credit balance - Warning - efsalarms"

  alarm_actions = [
    aws_sns_topic.efs_alarm.arn
  ]

  comparison_operator = "LessThanThreshold"

  dimensions = {
    FileSystemId = module.efs.id
  }

  evaluation_periods        = "5"
  insufficient_data_actions = []
  metric_name               = "BurstCreditBalance"
  namespace                 = "AWS/EFS"
  ok_actions                = []
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1132472146330"
}

resource "aws_cloudwatch_metric_alarm" "efs_burst_credit_balance_critical" {
  alarm_name        = "${local.name}-efs-burst-credit-balance-critical"
  alarm_description = "${module.efs.id} burst credit balance - Critical - efsalarms"

  alarm_actions = [
    aws_sns_topic.efs_alarm.arn
  ]

  comparison_operator = "LessThanThreshold"

  dimensions = {
    FileSystemId = module.efs.id
  }

  evaluation_periods        = "5"
  insufficient_data_actions = []
  metric_name               = "BurstCreditBalance"
  namespace                 = "AWS/EFS"
  ok_actions                = []
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "377497426330"
}

resource "aws_cloudwatch_metric_alarm" "efs_burst_credit_increase_threshold" {
  alarm_name        = "${local.name}-efs-burst-credit-increase-threshold"
  alarm_description = "Set ${module.efs.id} burst credit balance increase threshold - efsalarms"

  alarm_actions = [
    # TODO autoscaling
    aws_sns_topic.efs_alarm.arn
  ]

  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    FileSystemId = module.efs.id
  }

  evaluation_periods        = "5"
  insufficient_data_actions = []
  metric_name               = "PermittedThroughput"
  namespace                 = "AWS/EFS"
  ok_actions                = []
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "104857600"
}

resource "aws_cloudwatch_metric_alarm" "efs_burst_credit_decrease_threshold" {
  alarm_name        = "${local.name}-efs-burst-credit-decrease-threshold"
  alarm_description = "Set ${module.efs.id} burst credit balance decrease threshold - efsalarms"

  alarm_actions = [
    # TODO autoscaling
    aws_sns_topic.efs_alarm.arn
  ]

  comparison_operator = "LessThanThreshold"

  dimensions = {
    FileSystemId = module.efs.id
  }

  evaluation_periods        = "5"
  insufficient_data_actions = []
  metric_name               = "PermittedThroughput"
  namespace                 = "AWS/EFS"
  ok_actions                = []
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "104857600"
}

resource "aws_cloudwatch_dashboard" "dashboard_with_alarms" {
  dashboard_name = "${local.name}-dashboard-with-alarms"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 6,
        height = 6,
        properties = {
          view    = "timeSeries",
          stacked = false,
          metrics = [
            ["AWS/EFS", "TotalIOBytes", "FileSystemId", module.efs.id, { stat = "Sum", period = 60 }]
          ],
          region = data.aws_region.current.name,
          title  = "EFS Throughput"
        }
      },
      {
        type   = "metric",
        x      = 18,
        y      = 0,
        width  = 6,
        height = 3,
        properties = {
          view    = "singleValue",
          stacked = false,
          metrics = [
            ["AWS/EFS", "PermittedThroughput", "FileSystemId", module.efs.id, { stat = "Maximum" }]
          ],
          region = data.aws_region.current.name,
          title  = "EFS PermittedThroughput"
        }
      },
      {
        type   = "metric",
        x      = 6,
        y      = 0,
        width  = 6,
        height = 6,
        properties = {
          view    = "timeSeries",
          stacked = false,
          metrics = [
            ["AWS/EFS", "TotalIOBytes", "FileSystemId", module.efs.id, { stat = "SampleCount", period = 60 }]
          ],
          region = data.aws_region.current.name,
          title  = "EFS IOPS"
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 0,
        width  = 6,
        height = 6,
        properties = {
          view    = "timeSeries",
          stacked = false,
          metrics = [
            ["AWS/EFS", "BurstCreditBalance", "FileSystemId", module.efs.id, { stat = "Maximum", period = 60 }]
          ],
          region = data.aws_region.current.name,
          title  = "EFS BurstCreditBalance"
        }
      },
      {
        type   = "metric",
        x      = 18,
        y      = 3,
        width  = 6,
        height = 3,
        properties = {
          view = "singleValue",
          metrics = [
            ["Custom/EFS", "SizeInBytes", "FileSystemId", module.efs.id]
          ],
          region = data.aws_region.current.name,
          title  = "EFS SizeInBytes"
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 12,
        width  = 6,
        height = 6,
        properties = {
          view    = "timeSeries",
          stacked = false,
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", module.alb.dns_name, { stat = "Sum", period = 60 }]
          ],
          region = data.aws_region.current.name,
          title  = "ALB RequestCount"
        }
      },
      {
        type   = "metric",
        x      = 6,
        y      = 12,
        width  = 6,
        height = 6,
        properties = {
          view    = "timeSeries",
          stacked = false,
          metrics = [
            ["AWS/ApplicationELB", "ActiveConnectionCount", "LoadBalancer", module.alb.dns_name, { stat = "Sum", period = 60 }]
          ],
          region = data.aws_region.current.name,
          title  = "ALB ActiveConnectionCount"
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 12,
        width  = 6,
        height = 6,
        properties = {
          view    = "timeSeries",
          stacked = false,
          metrics = [
            ["AWS/RDS", "FreeableMemory", "Role", "READER", "DBClusterIdentifier", module.rds_aurora.cluster_id, { stat = "Sum", period = 60 }],
            ["AWS/RDS", "FreeableMemory", "Role", "WRITER", "DBClusterIdentifier", module.rds_aurora.cluster_id, { stat = "Sum", period = 60 }]
          ],
          region = data.aws_region.current.name,
          title  = "RDS FreeableMemory"
        }
      },
      {
        type   = "metric",
        x      = 18,
        y      = 12,
        width  = 6,
        height = 6,
        properties = {
          view    = "timeSeries",
          stacked = false,
          metrics = [
            ["AWS/RDS", "CPUUtilization", "Role", "READER", "DBClusterIdentifier", module.rds_aurora.cluster_id, { stat = "Sum", period = 60 }],
            ["AWS/RDS", "CPUUtilization", "Role", "WRITER", "DBClusterIdentifier", module.rds_aurora.cluster_id, { stat = "Sum", period = 60 }]
          ],
          region = data.aws_region.current.name,
          title  = "RDS CPUUtilization"
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 6,
        width  = 6,
        height = 6,
        properties = {
          title = "EFS Burst Credit Balance Increase Threshold",
          annotations = {
            alarms = [aws_cloudwatch_metric_alarm.efs_burst_credit_increase_threshold.arn]
          },
          view    = "timeSeries",
          stacked = false
        }
      },
      {
        type   = "metric",
        x      = 6,
        y      = 6,
        width  = 6,
        height = 6,
        properties = {
          title = "EFS Burst Credit Balance Decrease Threshold",
          annotations = {
            alarms = [aws_cloudwatch_metric_alarm.efs_burst_credit_decrease_threshold.arn]
          },
          view    = "timeSeries",
          stacked = false
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 6,
        width  = 6,
        height = 6,
        properties = {
          title = "EFS Burst Credit Balance - Warning",
          annotations = {
            alarms = [aws_cloudwatch_metric_alarm.efs_burst_credit_balance_warning.arn]
          },
          view    = "timeSeries",
          stacked = false
        }
      },
      {
        type   = "metric",
        x      = 18,
        y      = 6,
        width  = 6,
        height = 6,
        properties = {
          title = "EFS Burst Credit Balance - Critical",
          annotations = {
            alarms = [aws_cloudwatch_metric_alarm.efs_burst_credit_balance_critical.arn]
          },
          view    = "timeSeries",
          stacked = false
        }
      }
    ]
  })
}

resource "aws_cloudwatch_dashboard" "dashboard_with_no_alarms" {
  dashboard_name = "${local.name}-dashboard-with-no-alarms"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 6,
        height = 6,
        properties = {
          view    = "timeSeries",
          stacked = false,
          metrics = [
            ["AWS/EFS", "TotalIOBytes", "FileSystemId", module.efs.id, { stat = "Sum", period = 60 }]
          ],
          region = data.aws_region.current.name,
          title  = "EFS Throughput"
        }
      },
      {
        type   = "metric",
        x      = 18,
        y      = 0,
        width  = 6,
        height = 3,
        properties = {
          view    = "singleValue",
          stacked = false,
          metrics = [
            ["AWS/EFS", "PermittedThroughput", "FileSystemId", module.efs.id, { stat = "Maximum" }]
          ],
          region = data.aws_region.current.name,
          title  = "EFS PermittedThroughput"
        }
      },
      {
        type   = "metric",
        x      = 6,
        y      = 0,
        width  = 6,
        height = 6,
        properties = {
          view    = "timeSeries",
          stacked = false,
          metrics = [
            ["AWS/EFS", "TotalIOBytes", "FileSystemId", module.efs.id, { stat = "SampleCount", period = 60 }]
          ],
          region = data.aws_region.current.name,
          title  = "EFS IOPS"
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 0,
        width  = 6,
        height = 6,
        properties = {
          view    = "timeSeries",
          stacked = false,
          metrics = [
            ["AWS/EFS", "BurstCreditBalance", "FileSystemId", module.efs.id, { stat = "Maximum", period = 60 }]
          ],
          region = data.aws_region.current.name,
          title  = "EFS BurstCreditBalance"
        }
      },
      {
        type   = "metric",
        x      = 18,
        y      = 3,
        width  = 6,
        height = 3,
        properties = {
          view = "singleValue",
          metrics = [
            ["Custom/EFS", "SizeInBytes", "FileSystemId", module.efs.id]
          ],
          region = data.aws_region.current.name,
          title  = "EFS SizeInBytes"
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 12,
        width  = 6,
        height = 6,
        properties = {
          view    = "timeSeries",
          stacked = false,
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", module.alb.dns_name, { stat = "Sum", period = 60 }]
          ],
          region = data.aws_region.current.name,
          title  = "ALB RequestCount"
        }
      },
      {
        type   = "metric",
        x      = 6,
        y      = 12,
        width  = 6,
        height = 6,
        properties = {
          view    = "timeSeries",
          stacked = false,
          metrics = [
            ["AWS/ApplicationELB", "ActiveConnectionCount", "LoadBalancer", module.alb.dns_name, { stat = "Sum", period = 60 }]
          ],
          region = data.aws_region.current.name,
          title  = "ALB ActiveConnectionCount"
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 12,
        width  = 6,
        height = 6,
        properties = {
          view    = "timeSeries",
          stacked = false,
          metrics = [
            ["AWS/RDS", "FreeableMemory", "Role", "READER", "DBClusterIdentifier", module.rds_aurora.cluster_id, { stat = "Sum", period = 60 }],
            ["AWS/RDS", "FreeableMemory", "Role", "WRITER", "DBClusterIdentifier", module.rds_aurora.cluster_id, { stat = "Sum", period = 60 }]
          ],
          region = data.aws_region.current.name,
          title  = "RDS FreeableMemory"
        }
      },
      {
        type   = "metric",
        x      = 18,
        y      = 12,
        width  = 6,
        height = 6,
        properties = {
          view    = "timeSeries",
          stacked = false,
          metrics = [
            ["AWS/RDS", "CPUUtilization", "Role", "READER", "DBClusterIdentifier", module.rds_aurora.cluster_id, { stat = "Sum", period = 60 }],
            ["AWS/RDS", "CPUUtilization", "Role", "WRITER", "DBClusterIdentifier", module.rds_aurora.cluster_id, { stat = "Sum", period = 60 }]
          ],
          region = data.aws_region.current.name,
          title  = "RDS CPUUtilization"
        }
      }
    ]
  })
}

output "cloudwatch_efs_burst_credit_balance_critical_arn" {
  value = aws_cloudwatch_metric_alarm.efs_burst_credit_balance_critical.arn
}

output "cloudwatch_efs_burst_credit_balance_warning_arn" {
  value = aws_cloudwatch_metric_alarm.efs_burst_credit_balance_warning.arn
}

output "cloudwatch_efs_burst_credit_decrease_threshold_arn" {
  value = aws_cloudwatch_metric_alarm.efs_burst_credit_decrease_threshold.arn
}

output "cloudwatch_efs_burst_credit_increase_threshold_arn" {
  value = aws_cloudwatch_metric_alarm.efs_burst_credit_increase_threshold.arn
}
