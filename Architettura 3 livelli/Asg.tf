########################################
# ASG FRONTEND – us-west-2 (DR)
########################################
resource "aws_autoscaling_group" "frontend_asg_west" {
  provider         = aws.secondary
  name             = "asg-frontend-west"
  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  launch_template {
    id      = aws_launch_template.frontend_lt_west.id
    version = "$Latest"
  }

  vpc_zone_identifier = [
    aws_subnet.dr["pri-sub-3a"].id,
    aws_subnet.dr["pri-sub-4b"].id
  ]

  target_group_arns = [
    aws_lb_target_group.tg_frontend_dr.arn
  ]

  health_check_type = "ELB"

  lifecycle { create_before_destroy = true }

  tag {
    key                 = "Name"
    value               = "frontend-dr"
    propagate_at_launch = true
  }

  depends_on = [aws_lb_target_group.tg_frontend_dr]
}

########################################
# ASG BACKEND – us-west-2 (DR)
########################################
resource "aws_autoscaling_group" "backend_asg_west" {
  provider         = aws.secondary
  name             = "asg-backend-west"
  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  launch_template {
    id      = aws_launch_template.backend_lt_west.id
    version = "$Latest"
  }

  vpc_zone_identifier = [
    aws_subnet.dr["pri-sub-5a"].id,
    aws_subnet.dr["pri-sub-6b"].id
  ]

  target_group_arns = [
    aws_lb_target_group.tg_backend_dr.arn
  ]

  health_check_type = "ELB"

  lifecycle { create_before_destroy = true }

  tag {
    key                 = "Name"
    value               = "backend-dr"
    propagate_at_launch = true
  }

  depends_on = [aws_lb_target_group.tg_backend_dr]
}
