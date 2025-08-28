##############################
# SG per Bastion (prod)
##############################
resource "aws_security_group" "bastion" {
  provider    = aws.primary
  name        = "bastion-sg"
  description = "SSH access only from trusted IP"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description = "SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##############################
# SG per ALB Frontend (prod)
##############################
resource "aws_security_group" "frontend_alb" {
  provider    = aws.primary
  name        = "frontend-alb-sg"
  description = "Allow HTTP/HTTPS from anywhere"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##############################
# SG per ALB Backend (prod)
##############################
resource "aws_security_group" "backend_alb" {
  provider    = aws.primary
  name        = "backend-alb-sg"
  description = "Allow HTTP/HTTPS from anywhere"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##############################
# SG per EC2 Frontend (prod)
##############################
resource "aws_security_group" "frontend_ec2" {
  provider    = aws.primary
  name        = "frontend-ec2-sg"
  description = "Allow HTTP from frontend ALB and SSH from bastion"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description     = "HTTP from ALB Frontend"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_alb.id]
  }
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##############################
# SG per EC2 Backend (prod)
##############################
resource "aws_security_group" "backend_ec2" {
  provider    = aws.primary
  name        = "backend-ec2-sg"
  description = "Allow HTTP from backend ALB and SSH from bastion"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description     = "HTTP from ALB Backend"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_alb.id]
  }
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##############################
# SG per RDS (prod)
##############################
resource "aws_security_group" "rds" {
  provider    = aws.primary
  name        = "rds-sg"
  description = "Allow MySQL/Aurora from backend EC2 only"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description     = "MySQL from Backend EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##############################
# SG per RDS (DR)
##############################
resource "aws_security_group" "rds_dr" {
  provider    = aws.secondary
  name        = "rds-dr-sg"
  description = "Allow MySQL/Aurora in DR"
  vpc_id      = aws_vpc.dr.id

  ingress {
    description = "MySQL ingress (adjust later)"
    protocol    = "tcp"
    from_port   = 3306
    to_port     = 3306
    cidr_blocks = ["0.0.0.0/0"] # sostituisci con SG backend_ec2 DR quando lo avrai
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "rds-dr-sg" }
}

#/ Security Group per ALB Frontend
resource "aws_security_group" "alb_frontend_sg" {
  provider    = aws.primary
  name        = "alb-frontend-sg"
  description = "Allow HTTP/HTTPS for frontend ALB"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-frontend-sg"
  }
}

resource "aws_security_group" "frontend_ec2_dr" {
  provider    = aws.secondary
  name        = "frontend-ec2-dr-sg"
  description = "Allow HTTP and SSH (DR)"
  vpc_id      = aws_vpc.dr.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # oppure bastion DR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend_ec2_dr" {
  provider    = aws.secondary
  name        = "backend-ec2-dr-sg"
  description = "Allow HTTP and SSH (DR)"
  vpc_id      = aws_vpc.dr.id

  ingress {
    description = "HTTP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "alb-frontend-sg"
  }
}

########################################
# SG per ALB Frontend (DR)
########################################
resource "aws_security_group" "alb_frontend_dr_sg" {
  provider    = aws.secondary
  name        = "alb-frontend-dr-sg"
  description = "Allow HTTP/HTTPS to frontend ALB in DR"
  vpc_id      = aws_vpc.dr.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-frontend-dr-sg" }
}

# L'EC2 frontend deve accettare 80 dal SG dell'ALB (non da Internet)
resource "aws_security_group_rule" "allow_alb_to_frontend_80" {
  provider                 = aws.primary
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.frontend_ec2.id    # SG EC2 frontend
  source_security_group_id = aws_security_group.alb_frontend_sg.id # SG ALB frontend
}

