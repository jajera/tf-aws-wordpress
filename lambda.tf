resource "aws_lambda_function" "size_monitor" {
  filename         = "${path.module}/external/lambda_size_monitor.zip"
  function_name    = "${local.name}-size-monitor"
  role             = aws_iam_role.size_monitor.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/external/lambda_size_monitor.zip")
  runtime          = "python3.12"
  timeout          = 60

  environment {
    variables = {
      filesystemid = module.efs.id
      region       = data.aws_region.current.name
    }
  }
}
// TODO - lamda code error
# [ERROR] Runtime.UserCodeSyntaxError: Syntax error in module 'index': Missing parentheses in call to 'print'. Did you mean print(...)? (index.py, line 7)
# Traceback (most recent call last):
#   File "/var/task/index.py" Line 7
#             print "Unable to get the environment variable filesystemid"

resource "aws_lambda_permission" "size_monitor" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.size_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.size_monitor.arn
}
