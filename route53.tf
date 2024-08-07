resource "aws_route53_zone" "wordpress" {
  name = "${aws_cloudfront_distribution.wordpress.domain_name}."
}

resource "aws_route53_record" "wordpress" {
  zone_id = aws_route53_zone.wordpress.id
  name    = "www.${aws_cloudfront_distribution.wordpress.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.wordpress.domain_name
    zone_id                = aws_cloudfront_distribution.wordpress.hosted_zone_id
    evaluate_target_health = true
  }
}
