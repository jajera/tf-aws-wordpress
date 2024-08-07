module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.10.0"

  name                       = local.name
  enable_deletion_protection = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = module.vpc.public_subnets
  vpc_id                     = module.vpc.vpc_id

  create_security_group = false

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "wordpress"
      }
    }
  }

  target_groups = {
    wordpress = {
      name              = local.name
      create_attachment = false

      health_check = {
        path                = "/wp-login.php"
        interval            = 30
        timeout             = 29
        healthy_threshold   = 5
        unhealthy_threshold = 10
        protocol            = "HTTP"
      }

      port        = 80
      protocol    = "HTTP"
      target_type = "instance"
    }
  }
}

output "alb_dns_name" {
  value = module.alb.dns_name
}
