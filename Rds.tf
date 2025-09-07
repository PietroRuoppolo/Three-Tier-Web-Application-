############################
# Subnet group primario
############################
resource "aws_db_subnet_group" "main" {
  provider = aws.primary
  name     = "main-db-subnet-group"

  subnet_ids = [
    aws_subnet.prod["pri-sub-7a"].id,
    aws_subnet.prod["pri-sub-8b"].id
  ]

  tags = { Name = "MainDBSubnetGroup" }
}

############################
# Subnet group replica (DR)
############################
resource "aws_db_subnet_group" "replica" {
  provider = aws.secondary
  name     = "recovery-db-subnet-group"

  subnet_ids = [
    aws_subnet.dr["pri-sub-7a"].id,
    aws_subnet.dr["pri-sub-8b"].id
  ]

  tags = { Name = "RecoveryDBSubnetGroup" }
}

############################
# Istanza RDS primaria (us-east-1)
############################
resource "aws_db_instance" "primary_db" {
  provider   = aws.primary
  identifier = "db-prod"

  engine         = "mysql"
  engine_version = var.mysql_version
  instance_class = var.instance_type

  allocated_storage = var.storage_size
  storage_type      = "gp2"

  # Credenziali
  username                      = var.db_username
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.secrets.arn

  # Nome DB:
  db_name = var.db_name

  multi_az            = true
  publicly_accessible = false

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window           = "03:00-04:00"

  # Snapshot finale al destroy (obbligatorio)
  skip_final_snapshot       = false
  final_snapshot_identifier = "db-prod-final-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  deletion_protection = false
  storage_encrypted   = true # usa KMS gestita da AWS per il volume dati
}

############################
# Data source KMS default per RDS in DR (alias/aws/rds)
############################
data "aws_kms_alias" "rds_default_dr" {
  provider = aws.secondary
  name     = "alias/aws/rds"
}

############################
# Read replica in DR (us-west-2)
############################
resource "aws_db_instance" "read_replica" {
  provider   = aws.secondary
  identifier = "db-prod-recovery"

  replicate_source_db = aws_db_instance.primary_db.arn
  instance_class      = var.instance_type

  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.replica.name
  vpc_security_group_ids = [aws_security_group.rds_dr.id]

  storage_type      = "gp2"
  storage_encrypted = true
  kms_key_id        = data.aws_kms_alias.rds_default_dr.target_key_arn

  # Le read-replica NON hanno snapshot finale
  skip_final_snapshot = true

  depends_on = [aws_db_instance.primary_db]
}
