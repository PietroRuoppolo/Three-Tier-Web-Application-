
############################
# VARS (no prompt)
############################
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "key_pair_name" {
  type    = string
  default = "auto-temp-key"
} ###########################
# TLS KEY (one shot, reused in both regions)
############################
resource "tls_private_key" "auto" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# save PEM locally (chmod 0600)
resource "local_file" "pem" {
  filename        = "${path.module}/auto-temp-key.pem"
  content         = tls_private_key.auto.private_key_pem
  file_permission = "0600"
}

############################
# KEY PAIR in east + west
############################
resource "aws_key_pair" "deployer_east" {
  provider   = aws.primary
  key_name   = var.key_pair_name
  public_key = tls_private_key.auto.public_key_openssh
}

resource "aws_key_pair" "deployer_west" {
  provider   = aws.secondary
  key_name   = var.key_pair_name
  public_key = tls_private_key.auto.public_key_openssh
}

############################
# SECURITY GROUP in east + west
############################
resource "aws_security_group" "web_sg_east" {
  provider = aws.primary
  name     = "temp-web-sg-east"
  vpc_id   = aws_vpc.prod.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
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

resource "aws_security_group" "web_sg_west" {
  provider = aws.secondary
  name     = "temp-web-sg-west"
  vpc_id   = aws_vpc.dr.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }
  ingress {
    description = "HTTP" # opzionale, ma fa sempre comodo
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Ingress: HTTPS (TCP 443) da chiunque
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress: tutto il traffico in uscita
  egress {
    description = "All traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 = qualsiasi protocollo
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################
# AMI lookup per regione
############################
data "aws_ami" "ubuntu_east" {
  provider    = aws.primary
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_ami" "ubuntu_west" {
  provider    = aws.secondary
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

############################
# USER‑DATA (riuso)
############################
locals {
  frontend_user_data = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - apache2
    write_files:
      - path: /var/www/html/index.html
        permissions: '0644'
        owner: root:root
        content: |
          <!doctype html><html lang="en"><meta charset="utf-8">
          <title>AWS 3-Tier Architecture Demo</title>
          <meta name="viewport" content="width=device-width,initial-scale=1"/>
          <style>
            body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;background:#0b1220;color:#e7eef7;margin:0;padding:40px}
            .card{max-width:780px;margin:0 auto;background:#0f172a;border:1px solid #1f2a44;border-radius:16px;padding:28px;text-align:center}
            h1{margin:0 0 8px;font-size:28px}
            p{opacity:.85;line-height:1.6}
            .tags{margin-top:14px;font-size:14px;opacity:.8}
            .ok{display:inline-block;margin-top:10px;padding:6px 10px;border-radius:999px;background:#10b981;color:#052;font-weight:600}
          </style>
          <div class="card">
            <h1>🚀 AWS 3-Tier Architecture Demo</h1>
            <p>Deployed con <b>Terraform</b> — CloudFront → ALB → EC2.</p>
            <p class="tags">VPC · EC2 · ALB · Route 53 · ACM · (opz.) WAF</p>
            <div class="ok">LIVE</div>
          </div>
    runcmd:
      - systemctl enable apache2
      - systemctl restart apache2
  EOF


  backend_user_data = <<-EOF
    #!/bin/bash
    set -xe
    apt update -y
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    npm install -g corepack
    corepack enable
    corepack prepare yarn@stable --activate --yes
    yarn global add pm2
    git clone https://github.com/AnkitJodhani/2nd10WeeksofCloudOps.git /opt/app
    cd /opt/app/backend
    npm install
    npm install dotenv
    echo 'DB_USER=dbuser'     >> .env
    echo 'DB_PASSWORD=dbpass' >> .env
    pm2 start index.js --name backendApi
  EOF
}

############################
# EC2 east
############################
resource "aws_instance" "frontend_east" {
  provider                    = aws.primary
  ami                         = data.aws_ami.ubuntu_east.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.deployer_east.key_name
  subnet_id                   = aws_subnet.prod["pub-sub-1a"].id
  vpc_security_group_ids      = [aws_security_group.web_sg_east.id]
  associate_public_ip_address = true
  user_data                   = local.frontend_user_data
  tags                        = { Name = "linux-frontend-east-1" }
}

resource "aws_instance" "backend_east" {
  provider                    = aws.primary
  ami                         = data.aws_ami.ubuntu_east.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.deployer_east.key_name
  subnet_id                   = aws_subnet.prod["pub-sub-2b"].id
  vpc_security_group_ids      = [aws_security_group.web_sg_east.id]
  associate_public_ip_address = true
  user_data                   = local.backend_user_data
  tags                        = { Name = "linux-backend-est-1" }
}

############################
# EC2 west (DR)
############################
resource "aws_instance" "frontend_west" {
  provider                    = aws.secondary
  ami                         = data.aws_ami.ubuntu_west.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.deployer_west.key_name
  subnet_id                   = aws_subnet.dr["pub-sub-1a"].id
  vpc_security_group_ids      = [aws_security_group.web_sg_west.id]
  associate_public_ip_address = true
  user_data                   = local.frontend_user_data
  tags                        = { Name = "linux-frontend-west-1" }
}

resource "aws_instance" "backend_west" {
  provider                    = aws.secondary
  ami                         = data.aws_ami.ubuntu_west.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.deployer_west.key_name
  subnet_id                   = aws_subnet.dr["pub-sub-2b"].id
  vpc_security_group_ids      = [aws_security_group.web_sg_west.id]
  associate_public_ip_address = true
  user_data                   = local.backend_user_data
  tags                        = { Name = "linux-backend-west-1" }
}

############################
# OUTPUTS
############################
output "frontend_east_ip" { value = aws_instance.frontend_east.public_ip }
output "backend_east_ip" { value = aws_instance.backend_east.public_ip }
output "frontend_west_ip" { value = aws_instance.frontend_west.public_ip }
output "backend_west_ip" { value = aws_instance.backend_west.public_ip }

output "private_key_pem" {
  value     = tls_private_key.auto.private_key_pem
  sensitive = true
}

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "terraform-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.ec2_key.private_key_pem
  filename        = "${path.module}/terraform-key.pem"
  file_permission = "0600"
}

resource "aws_key_pair" "ec2_key" {
  provider   = aws.primary
  key_name   = "multi-region-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

output "ec2_private_key_pem" {
  value     = tls_private_key.ec2_key.private_key_pem
  sensitive = true
}

/*resource "aws_security_group" "bastion_sg" {
  provider = aws.primary   # o .secondary, dipende da dove lo vuoi
  name   = "bastion-jump-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description      = "SSH from my IP"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["<IL TUO IP>/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion" {
  provider          = aws.primary
  ami               = data.aws_ami.ubuntu_22.id
  instance_type     = "t2.micro"
  subnet_id         = aws_subnet.pub_sub_1a.id
  key_name          = aws_key_pair.deployer_east.key_name
  security_groups   = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "bastion-jump-server"
  }
} */
