module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.9.0"

  name = local.name
  cidr = local.vpc_cidr

  azs              = local.azs
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 11)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 7, k + 21)]
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 1)]

  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  single_nat_gateway     = true
}

data "http" "my_public_ip" {
  url = "http://ifconfig.me/ip"
}

resource "aws_security_group" "alb" {
  description = "Security group for ALB"
  name        = "${local.name}-alb"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-alb"
  }
}

resource "aws_security_group" "bastion" {
  description = "Security group for Bastion instances"
  name        = "${local.name}-bastion"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.my_public_ip.response_body}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-bastion"
  }
}

resource "aws_security_group" "elasticache" {
  description = "Security group for ElastiCache cluster"
  name        = "${local.name}-elasticache"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 11211
    to_port   = 11211
    protocol  = "tcp"
    security_groups = [
      aws_security_group.web.id
    ]
  }

  tags = {
    Name = "${local.name}-elasticache"
  }
}

resource "aws_security_group" "efs" {
  description = "Security group for EFS mount targets"
  name        = "${local.name}-efs"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    security_groups = [
      aws_security_group.bastion.id
    ]
  }

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    security_groups = [
      aws_security_group.web.id
    ]
  }

  tags = {
    Name = "${local.name}-efs"
  }
}

resource "aws_security_group" "mysql" {
  description = "Security group for Amazon RDS MySQL cluster"
  name        = "${local.name}-mysql"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    security_groups = [
      aws_security_group.web.id
    ]
  }

  tags = {
    Name = "${local.name}-mysql"
  }
}

resource "aws_security_group" "web" {
  description = "Security group for web instances"
  name        = "${local.name}-web"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    security_groups = [
      aws_security_group.bastion.id
    ]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = [
      aws_security_group.alb.id
    ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [
      aws_security_group.alb.id
    ]
  }

  tags = {
    Name = "${local.name}-web"
  }
}
