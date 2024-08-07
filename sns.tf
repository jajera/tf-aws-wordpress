resource "aws_sns_topic" "efs_alarm" {
  name = "${local.name}-efs-alarm"
}

resource "aws_sns_topic_subscription" "efs_alarm" {
  topic_arn = aws_sns_topic.efs_alarm.arn
  protocol  = "email"
  endpoint  = "myemail@local"

  confirmation_timeout_in_minutes = 0
}
