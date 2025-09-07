resource "aws_kms_key" "secrets" {
  provider            = aws.primary
  description         = "CMK per segreti app/RDS/terraform state"
  enable_key_rotation = true
}
resource "aws_kms_alias" "secrets" {
  provider      = aws.primary
  name          = "alias/secrets-cmk"
  target_key_id = aws_kms_key.secrets.key_id
}
