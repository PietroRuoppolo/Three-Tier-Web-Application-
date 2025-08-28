##############################
# Target Groups – PRIMARIO (us-east-1)
##############################
resource "aws_lb_target_group" "backend_tg" {
  provider    = aws.primary
  name        = "ALB-backend-TG"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.prod.id
  target_type = "instance"

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "frontend_tg" {
  provider    = aws.primary
  name        = "ALB-frontend-TG"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.prod.id
  target_type = "instance"

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

##############################
# Application Load Balancers – PRIMARIO
##############################
# ALB FRONTEND
resource "aws_lb" "frontend_alb" {
  provider           = aws.primary
  name               = "ALB-frontend"
  internal           = false # deve essere pubblico, serve a CloudFront
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_frontend_sg.id]
  subnets = [
    aws_subnet.prod["pub-sub-1a"].id,
    aws_subnet.prod["pub-sub-2b"].id
  ]
  tags = { Name = "frontend-alb" }
}

resource "aws_lb_listener" "frontend_listener" {
  provider          = aws.primary
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "frontend_attach" {
  provider         = aws.primary
  target_group_arn = aws_lb_target_group.frontend_tg.arn
  target_id        = aws_instance.frontend_east.id
  port             = 80
}

# Prende le private della VPC per tag Tier=private
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.prod.id]
  }
  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}

# Usa le prime 2 AZ
locals {
  private_ids = try(data.aws_subnets.private.ids, [])
  use_private = length(local.private_ids) >= 2

  backend_subnets = local.use_private ? slice(local.private_ids, 0, 2) : [
    aws_subnet.prod["pub-sub-1a"].id,
    aws_subnet.prod["pub-sub-2b"].id
  ]
}

resource "aws_lb_listener" "backend_http_listener" {
  provider          = aws.primary
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "backend_attach" {
  provider         = aws.primary
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.backend_east.id
  port             = 80
}


resource "aws_lb_listener" "frontend_https_listener" {
  provider          = aws.primary
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.alb_origin_cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }

  depends_on = [aws_acm_certificate_validation.alb_origin_cert]
}

resource "aws_lb" "backend_alb" {
  provider           = aws.primary
  name               = "ALB-backend"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend_alb.id]
  subnets            = local.backend_subnets
  tags               = { Name = "backend-alb" }
}

