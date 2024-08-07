module "kms_efs" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases                 = ["efs/${local.name}"]
  description             = "EFS customer managed key"
  deletion_window_in_days = 7
}

module "kms_rds" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  deletion_window_in_days = 7
  description             = "KMS key for ${local.name} cluster activity stream."
  enable_key_rotation     = true
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"

  aliases = ["rds/${local.name}"]

  tags = local.tags
}
