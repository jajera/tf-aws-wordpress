## not part
# resource "tls_private_key" "example" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "aws_key_pair" "example" {
#   key_name   = "key1"
#   public_key = tls_private_key.example.public_key_openssh
# }

## not part

module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "1.6.3"

  # File system
  name        = local.name
  encrypted   = true
  kms_key_arn = module.kms_efs.key_arn

  # performance_mode                = "maxIO"
  # NB! PROVISIONED TROUGHPUT MODE WITH 256 MIBPS IS EXPENSIVE ~$1500/month
  # throughput_mode                 = "provisioned"
  # provisioned_throughput_in_mibps = 256

  lifecycle_policy = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  # File system policy
  attach_policy = false
  # bypass_policy_lockout_safety_check = false
  # policy_statements = [
  #   {
  #     sid     = "Example"
  #     actions = ["elasticfilesystem:ClientMount"]
  #     principals = [
  #       {
  #         type        = "AWS"
  #         identifiers = [data.aws_caller_identity.current.arn]
  #       }
  #     ]
  #   }
  # ]

  mount_targets              = { for k, v in zipmap(local.azs, module.vpc.private_subnets) : k => { subnet_id = v } }
  security_group_description = "Example EFS security group"
  security_group_vpc_id      = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      # relying on the defaults provdied for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = module.vpc.database_subnets_cidr_blocks
    }
  }

  # Backup policy
  enable_backup_policy = false

  tags = {
    Name      = local.name
    Terraform = "true"
  }

  depends_on = [
    module.kms_efs
  ]
}

output "efs_filesystem_id" {
  value = module.efs.id
}
