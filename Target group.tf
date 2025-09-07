resource "aws_lb_target_group" "tg_frontend_dr" {
  provider    = aws.secondary
  name        = "tg-frontend-dr"
  port        = 80 # HTTP
  protocol    = "HTTP"
  vpc_id      = aws_vpc.dr.id
  target_type = "instance"
  health_check { path = "/" }
}

resource "aws_lb_target_group" "tg_backend_dr" {
  provider    = aws.secondary
  name        = "tg-backend-dr"
  port        = 3000 # o la porta reale del backend
  protocol    = "HTTP"
  vpc_id      = aws_vpc.dr.id
  target_type = "instance"
  health_check { path = "/health" }
}
