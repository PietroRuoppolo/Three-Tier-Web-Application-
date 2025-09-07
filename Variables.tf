##############################
# Regione AWS (prod)
##############################
variable "aws_region_primary" {
  description = "AWS region for the primary environment (production)"
  type        = string
  default     = "us-east-1"
}

##############################
# Networking / Bastion
##############################
variable "allowed_ssh_cidr" {
  description = "CIDR allowed to reach the bastion via SSH (usa il tuo IP /32 in prod)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "vpc_name" {
  description = "Name to assign to the production VPC (creata da Terraform se non ne riusi una esistente)"
  type        = string
  default     = "prod-vpc"
}

# ——— Opzionali: compila SOLO se vuoi ri‑utilizzare rete esistente ———
/*variable "existing_vpc_id" {
  description = "ID della VPC già presente in AWS (es. vpc-0ab1c2d3e4f5g6h7)"
  type        = string
  default     = null
} */

variable "existing_pub_subnet_ids" {
  description = "Lista di subnet pubbliche in cui distribuire l'ALB (es. [\"subnet-…\",\"subnet-…\"])"
  type        = list(string)
  default     = [] # lista vuota → Terraform creerà le subnet
}
# ————————————————————————————————————————————————————————————————

##############################
# ACM / ALB HTTPS (facoltativo)
##############################
variable "backend_cert_arn" {
  description = "ARN del certificato ACM per il listener HTTPS del backend ALB (lascia vuoto se non usi HTTPS)"
  type        = string
  default     = ""
}

##############################
# Parametri RDS (primario + replica)
##############################
variable "mysql_version" {
  description = "MySQL engine version for both primary DB and replica"
  type        = string
  default     = "8.0"
}

variable "instance_type" {
  description = "Instance class for both primary and replica"
  type        = string
  default     = "db.t3.micro"
}

variable "storage_size" {
  description = "Allocated storage (GiB) for the primary DB"
  type        = number
  default     = 22
}

variable "db_name" {
  description = "Initial database name to create"
  type        = string
  default     = "test"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "admin"
}

/*variable "db_password" {
  description = "Master password for the RDS instance"
  type        = string
  sensitive   = true
} */

data "aws_ami" "al2_east" {
  provider    = aws.primary
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_launch_template" "frontend_lt_east" {
  provider               = aws.primary
  name_prefix            = "lt-frontend-east-"
  image_id               = data.aws_ami.al2_east.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deployer_east.key_name
  vpc_security_group_ids = [aws_security_group.web_sg_east.id]
}


variable "public_key_path" {
  description = "Percorso del file .pub"
  type        = string
  default     = "temp-key.pub"
}
variable "public_zone_id" {
  description = "ID della Route 53 hosted zone pubblica (Z00286601MI189KA69B8H)"
  type        = string
}

variable "origin_subdomain" {
  type        = string
  description = "Hostname usato da CloudFront per parlare con l'ALB"
  default     = "origin.threetier"
}

variable "alerts_email" {
  description = "Indirizzo email per ricevere alert SNS"
  type        = string
}
variable "budget_amount_usd" {
  description = "Budget mensile in USD per AWS Budgets"
  type        = string
  default     = "50" # metti un default se vuoi evitare prompt
}
variable "ce_service_monitor_arn" {
  description = "ARN del monitor DIMENSIONAL/SERVICE di Cost Anomaly Detection"
  type        = string
}
