resource "aws_cloudfront_distribution" "wordpress" {
  comment = "cloudfront"

  origin {
    domain_name = module.alb.dns_name
    origin_id   = "elb"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["SSLv3", "TLSv1"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  aliases = []

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "elb"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "allow-all"
    compress               = true

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  ordered_cache_behavior {
    path_pattern     = "wp-includes/*"
    target_origin_id = "elb"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    min_ttl          = 900
    default_ttl      = 900
    max_ttl          = 900

    forwarded_values {
      cookies {
        forward = "none"
      }

      headers      = ["Host"]
      query_string = true
    }

    compress               = true
    viewer_protocol_policy = "allow-all"
  }

  ordered_cache_behavior {
    path_pattern     = "wp-content/*"
    target_origin_id = "elb"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    min_ttl          = 900
    default_ttl      = 900
    max_ttl          = 900

    forwarded_values {
      cookies {
        forward = "none"
      }

      headers      = ["Host"]
      query_string = true
    }

    compress               = true
    viewer_protocol_policy = "allow-all"
  }

  price_class = "PriceClass_100"

  viewer_certificate {
    acm_certificate_arn            = null
    cloudfront_default_certificate = true
    ssl_support_method             = null
    minimum_protocol_version       = "TLSv1"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

output "cloudfront_dns_endpoint" {
  value = aws_cloudfront_distribution.wordpress.domain_name
}

output "cloudfront_dns_hostname" {
  value = "http://${aws_cloudfront_distribution.wordpress.domain_name}"
}

output "cloudfront_hosted_zone_id" {
  value = aws_cloudfront_distribution.wordpress.hosted_zone_id
}
