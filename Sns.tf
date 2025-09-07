
##############################
# SNS topics per regione/ambito
##############################
# Primario (us-east-1) – per ALB/RDS/ASG primari + EventBridge Backup
resource "aws_sns_topic" "alerts_primary" {
  provider = aws.primary
  name     = "prod-alerts-primary"
}
resource "aws_sns_topic_subscription" "alerts_email_primary" {
  provider  = aws.primary
  topic_arn = aws_sns_topic.alerts_primary.arn
  protocol  = "email"
  endpoint  = var.alerts_email
}

# DR (us-west-2) – per ASG/RDS/ALB in DR
resource "aws_sns_topic" "alerts_dr" {
  provider = aws.secondary
  name     = "prod-alerts-dr"
}
resource "aws_sns_topic_subscription" "alerts_email_dr" {
  provider  = aws.secondary
  topic_arn = aws_sns_topic.alerts_dr.arn
  protocol  = "email"
  endpoint  = var.alerts_email
}

# Global (us-east-1) – per CloudFront/Route53/Budgets/CE
resource "aws_sns_topic" "alerts_global" {
  provider = aws.useast1
  name     = "prod-alerts-global"
}
resource "aws_sns_topic_subscription" "alerts_email_global" {
  provider  = aws.useast1
  topic_arn = aws_sns_topic.alerts_global.arn
  protocol  = "email"
  endpoint  = var.alerts_email
}

##############################
# ALB – PRIMARIO (us-east-1)
##############################
resource "aws_cloudwatch_metric_alarm" "frontend_alb_5xx" {
  provider            = aws.primary
  alarm_name          = "ALB-Frontend-5xx-High"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 10
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { LoadBalancer = aws_lb.frontend_alb.arn_suffix }
  alarm_actions       = [aws_sns_topic.alerts_primary.arn]
  ok_actions          = [aws_sns_topic.alerts_primary.arn]
}

resource "aws_cloudwatch_metric_alarm" "frontend_alb_unhealthy" {
  provider            = aws.primary
  alarm_name          = "ALB-Frontend-UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = aws_lb.frontend_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.frontend_tg.arn_suffix
  }
  alarm_actions = [aws_sns_topic.alerts_primary.arn]
  ok_actions    = [aws_sns_topic.alerts_primary.arn]
}

resource "aws_cloudwatch_metric_alarm" "backend_alb_5xx" {
  provider            = aws.primary
  alarm_name          = "ALB-Backend-5xx-High"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 10
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { LoadBalancer = aws_lb.backend_alb.arn_suffix }
  alarm_actions       = [aws_sns_topic.alerts_primary.arn]
  ok_actions          = [aws_sns_topic.alerts_primary.arn]
}

resource "aws_cloudwatch_metric_alarm" "backend_alb_unhealthy" {
  provider            = aws.primary
  alarm_name          = "ALB-Backend-UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = aws_lb.backend_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.backend_tg.arn_suffix
  }
  alarm_actions = [aws_sns_topic.alerts_primary.arn]
  ok_actions    = [aws_sns_topic.alerts_primary.arn]
}

##############################
# CloudFront – GLOBAL (us-east-1)
##############################
resource "aws_cloudwatch_metric_alarm" "cf_5xx" {
  provider            = aws.useast1
  alarm_name          = "CF-High"
  namespace           = "AWS/CloudFront"
  metric_name         = "ErrorRate"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = 1
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.frontend_cdn.id
    Region         = "Global"
  }
  alarm_actions = [aws_sns_topic.alerts_global.arn]
  ok_actions    = [aws_sns_topic.alerts_global.arn]
}

##############################
# ASG – DR (us-west-2)
##############################
resource "aws_cloudwatch_metric_alarm" "asg_frontend_inservice_lt_desired" {
  provider            = aws.secondary
  alarm_name          = "ASG-Frontend-InServiceLTDesired"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  treat_missing_data  = "breaching"

  metric_query {
    id = "inserv"
    metric {
      namespace   = "AWS/AutoScaling"
      metric_name = "GroupInServiceInstances"
      period      = 60
      stat        = "Average"
      dimensions  = { AutoScalingGroupName = aws_autoscaling_group.frontend_asg_west.name }
    }
  }
  metric_query {
    id = "des"
    metric {
      namespace   = "AWS/AutoScaling"
      metric_name = "GroupDesiredCapacity"
      period      = 60
      stat        = "Average"
      dimensions  = { AutoScalingGroupName = aws_autoscaling_group.frontend_asg_west.name }
    }
  }
  metric_query {
    id          = "breach"
    expression  = "IF(inserv < des, 1, 0)"
    label       = "Frontend InService < Desired"
    return_data = true
  }
  alarm_actions = [aws_sns_topic.alerts_dr.arn]
  ok_actions    = [aws_sns_topic.alerts_dr.arn]
}

resource "aws_cloudwatch_metric_alarm" "asg_backend_inservice_lt_desired" {
  provider            = aws.secondary
  alarm_name          = "ASG-Backend-InServiceLTDesired"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  treat_missing_data  = "breaching"

  metric_query {
    id = "inserv"
    metric {
      namespace   = "AWS/AutoScaling"
      metric_name = "GroupInServiceInstances"
      period      = 60
      stat        = "Average"
      dimensions  = { AutoScalingGroupName = aws_autoscaling_group.backend_asg_west.name }
    }
  }
  metric_query {
    id = "des"
    metric {
      namespace   = "AWS/AutoScaling"
      metric_name = "GroupDesiredCapacity"
      period      = 60
      stat        = "Average"
      dimensions  = { AutoScalingGroupName = aws_autoscaling_group.backend_asg_west.name }
    }
  }
  metric_query {
    id          = "breach"
    expression  = "IF(inserv < des, 1, 0)"
    label       = "Backend InService < Desired"
    return_data = true
  }
  alarm_actions = [aws_sns_topic.alerts_dr.arn]
  ok_actions    = [aws_sns_topic.alerts_dr.arn]
}

##############################
# RDS – PRIMARIO (us-east-1)
##############################
resource "aws_cloudwatch_metric_alarm" "rds_cpu_primary" {
  provider            = aws.primary
  alarm_name          = "RDS-Primary-CPU-High"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { DBInstanceIdentifier = aws_db_instance.primary_db.id }
  alarm_actions       = [aws_sns_topic.alerts_primary.arn]
  ok_actions          = [aws_sns_topic.alerts_primary.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_storage_low_primary" {
  provider            = aws.primary
  alarm_name          = "RDS-Primary-FreeStorage-Low"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 5000000000
  comparison_operator = "LessThanThreshold"
  dimensions          = { DBInstanceIdentifier = aws_db_instance.primary_db.id }
  alarm_actions       = [aws_sns_topic.alerts_primary.arn]
  ok_actions          = [aws_sns_topic.alerts_primary.arn]
}

##############################
# RDS – DR (us-west-2)
##############################
resource "aws_cloudwatch_metric_alarm" "rds_cpu_dr" {
  provider            = aws.secondary
  alarm_name          = "RDS-DR-CPU-High"
  namespace           = "AWS/RDS"
  metric_name         = "CPU-Utilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { DBInstanceIdentifier = aws_db_instance.read_replica.id }
  alarm_actions       = [aws_sns_topic.alerts_dr.arn]
  ok_actions          = [aws_sns_topic.alerts_dr.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_replica_lag_dr" {
  provider            = aws.secondary
  alarm_name          = "RDS-DR-ReplicaLag-High"
  namespace           = "AWS/RDS"
  metric_name         = "ReplicaLag"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = 60
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { DBInstanceIdentifier = aws_db_instance.read_replica.id }
  alarm_actions       = [aws_sns_topic.alerts_dr.arn]
  ok_actions          = [aws_sns_topic.alerts_dr.arn]
}

##############################
# Route53 Health Check + Alarm (GLOBAL/us-east-1)
##############################
resource "aws_route53_health_check" "backend_hc" {
  fqdn          = aws_lb.frontend_alb.dns_name
  port          = 443
  type          = "HTTPS"
  resource_path = "/healthz"

  request_interval  = 30
  failure_threshold = 3
  regions           = ["us-east-1", "us-west-2", "eu-west-1"]

  tags = { Name = "backend-hc" }
}


resource "aws_cloudwatch_metric_alarm" "r53_hc" {
  provider            = aws.useast1
  alarm_name          = "Route53-HealthCheck-Failed"
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  dimensions          = { HealthCheckId = aws_route53_health_check.backend_hc.id }
  alarm_actions       = [aws_sns_topic.alerts_global.arn]
  ok_actions          = [aws_sns_topic.alerts_global.arn]
  treat_missing_data  = "breaching"
}

##############################
# EventBridge – Backup failed → SNS (PRIMARIO)
##############################
resource "aws_cloudwatch_event_rule" "backup_failed" {
  provider    = aws.primary
  name        = "aws-backup-failed"
  description = "Alert su job di backup falliti"
  event_pattern = jsonencode({
    "source" : ["aws.backup"],
    "detail-type" : ["Backup Job State Change"],
    "detail" : { "state" : ["FAILED"] }
  })
}

resource "aws_cloudwatch_event_target" "backup_to_sns" {
  provider  = aws.primary
  rule      = aws_cloudwatch_event_rule.backup_failed.name
  target_id = "backup-sns"
  arn       = aws_sns_topic.alerts_primary.arn
}
