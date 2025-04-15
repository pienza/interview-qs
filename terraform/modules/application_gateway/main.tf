resource "aws_acm_certificate" "training" {
  domain_name       = "training.inflection.io"
  validation_method = "DNS"

  tags = {
    Name        = "${var.environment}-training-cert"
    Environment = var.environment
  }
}

resource "aws_route53_record" "training_validation" {
  for_each = {
    for dvo in aws_acm_certificate.training.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

resource "aws_acm_certificate_validation" "training" {
  certificate_arn         = aws_acm_certificate.training.arn
  validation_record_fqdns = [for record in aws_route53_record.training_validation : record.fqdn]
}

resource "aws_alb" "training" {
  name               = "${var.environment}-training-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name        = "${var.environment}-training-alb"
    Environment = var.environment
  }
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_alb.training.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.training.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.training.arn
  }
}

resource "aws_alb_target_group" "training" {
  name        = "${var.environment}-training-tg"
  port        = 443
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 3000
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name        = "${var.environment}-training-tg"
    Environment = var.environment
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
  }
}

resource "aws_route53_record" "training" {
  zone_id = var.route53_zone_id
  name    = "training.inflection.io"
  type    = "A"

  alias {
    name                   = aws_alb.training.dns_name
    zone_id                = aws_alb.training.zone_id
    evaluate_target_health = true
  }
} 