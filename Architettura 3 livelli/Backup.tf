provider "aws" {
  alias  = "east"
  region = "us-east-1"
}
# Vault di backup in us-east-1
resource "aws_backup_vault" "vault_east" {
  provider = aws.east
  name     = "vault-east"
}

# IAM Role per AWS Backup
resource "aws_iam_role" "aws_backup_role" {
  name = "aws-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "backup.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "aws_backup_role_attach" {
  role       = aws_iam_role.aws_backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Backup Plan
resource "aws_backup_plan" "ec2_backup_plan" {
  provider = aws.east
  name     = "daily-backup-plan"

  rule {
    rule_name         = "daily-ec2-backup"
    target_vault_name = aws_backup_vault.vault_east.name
    schedule          = "cron(0 5 * * ? *)"
    start_window      = 60
    completion_window = 180

    lifecycle {
      delete_after = 30
    }

    copy_action {
      destination_vault_arn = "arn:aws:backup:us-west-2:${data.aws_caller_identity.current.account_id}:backup-vault:Default"
      lifecycle {
        delete_after = 30
      }
    }
  }
}

# Selezione risorse EC2 da includere nel backup
resource "aws_backup_selection" "ec2_selection" {
  provider     = aws.east
  name         = "frontend-backend-east"
  iam_role_arn = aws_iam_role.aws_backup_role.arn
  plan_id      = aws_backup_plan.ec2_backup_plan.id

  resources = [
    aws_instance.frontend_east.arn,
    aws_instance.backend_east.arn
  ]
}

data "aws_caller_identity" "current" {}
