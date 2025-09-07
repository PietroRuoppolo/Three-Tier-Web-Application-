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

# Il secret ARN viene esposto da RDS quando manage_master_user_password è attivo
# (lista con un solo elemento -> [0])
data "aws_iam_policy_document" "app_secrets_access" {
  statement {
    sid     = "ReadDBSecret"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_db_instance.primary_db.master_user_secret[0].secret_arn
    ]
  }
  statement {
    sid       = "AllowKMSDecrypt"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.secrets.arn]
  }
}

resource "aws_iam_policy" "app_secrets_access" {
  name   = "app-secrets-access"
  policy = data.aws_iam_policy_document.app_secrets_access.json
}

resource "aws_iam_role_policy_attachment" "attach_app_secrets_access" {
  role       = aws_iam_role.backend_ssm.name
  policy_arn = aws_iam_policy.app_secrets_access.arn
}
