resource "aws_budgets_budget" "monthly_cost" {
  provider    = aws.useast1
  name        = "MonthlyBudget"
  budget_type = "COST"
  time_unit   = "MONTHLY"

  limit_amount = var.budget_amount_usd
  limit_unit   = "USD"

  cost_types {
    include_tax          = true
    include_subscription = true
    use_blended          = false
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alerts_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alerts_email]
  }
}
resource "aws_ce_anomaly_subscription" "anomaly_alert" {
  provider         = aws.useast1
  name             = "CostAnomalyAlert"
  frequency        = "DAILY"
  monitor_arn_list = [var.ce_service_monitor_arn]

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["10"]
    }
  }

  subscriber {
    type    = "EMAIL"
    address = var.alerts_email
  }
}


