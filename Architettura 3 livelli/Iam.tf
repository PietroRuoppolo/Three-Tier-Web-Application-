resource "aws_iam_role" "backend_ssm" {
  name               = "backend-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "backend_ssm_core" {
  role       = aws_iam_role.backend_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_instance_profile" "backend_ssm" {
  name = "backend-ssm-profile"
  role = aws_iam_role.backend_ssm.name
}

# Costruisco la policy in modo sicuro
data "aws_iam_policy_document" "sns_budgets_ce" {
  statement {
    sid     = "AllowBudgetsPublish"
    effect  = "Allow"
    actions = ["SNS:Publish"]
    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }
    resources = [aws_sns_topic.alerts_global.arn]
  }

  statement {
    sid     = "AllowCEAnomalyPublish"
    effect  = "Allow"
    actions = ["SNS:Publish"]
    principals {
      type        = "Service"
      identifiers = ["ce.amazonaws.com"]
    }
    resources = [aws_sns_topic.alerts_global.arn]
  }
}
