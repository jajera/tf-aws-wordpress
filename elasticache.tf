module "elasticache" {
  source                   = "terraform-aws-modules/elasticache/aws"
  version                  = "1.2.2"
  cluster_id               = local.name
  create_cluster           = true
  create_replication_group = false
  create_security_group    = false

  engine          = "memcached"
  engine_version  = "1.6.22"
  node_type       = "cache.t3.micro"
  num_cache_nodes = 2
  az_mode         = "cross-az"

  maintenance_window = "sun:15:00-sun:16:00"
  apply_immediately  = true

  # Security group
  security_group_ids = [
    aws_security_group.elasticache.id
  ]

  # Subnet Group
  subnet_ids = module.vpc.private_subnets

  # Parameter Group
  create_parameter_group = true
  parameter_group_family = "memcached1.6"
  parameters = [
    {
      name  = "idle_timeout"
      value = 60
    }
  ]

  tags = {
    Terraform = "true"
    Name      = "WordPress / elasticache"
  }
}
