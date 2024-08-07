resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  region = "ap-southeast-1"
  name   = "wordpress-${random_string.suffix.result}"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  # efs
  data_directory = "demo"
  growth         = 5
  copy_system_id = module.efs.id
  wp_dir         = "demo"

  tags = {
    # Name       = local.name
  }
}

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "random_password" "rds_aurora" {
  length           = 16
  special          = true
  override_special = "_!#%&*()-<=>?[]^_{|}~"
}

# data "template_file" "efs_sh" {
#   template = file("${path.module}/external/efs.sh.tpl")

#   vars = {
#     S3_BUCKET = aws_s3_bucket.wordpress.bucket
#   }
# }
