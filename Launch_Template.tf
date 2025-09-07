# ---------------------------
# locals.tf
# ---------------------------
locals {
  ami_timestamp = formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())

  user_data_frontend = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sleep 90
    sudo systemctl start apache2.service
  EOF

  user_data_backend = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sleep 150
    sudo pm2 startup
    sudo env PATH=$PATH:/usr/bin /usr/local/share/.config/yarn/global/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu
    sudo systemctl start pm2-root
    sudo systemctl enable pm2-root
  EOF
}

resource "aws_launch_template" "backend_lt_east" {
  provider               = aws.primary
  name_prefix            = "lt-backend-east-"
  image_id               = aws_ami_from_instance.backend_ami_east.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer_east.key_name
  vpc_security_group_ids = [aws_security_group.backend_ec2.id]
  user_data              = base64encode(local.user_data_backend)
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "frontend_lt_west" {
  provider               = aws.secondary
  name_prefix            = "lt-frontend-west-"
  image_id               = aws_ami_from_instance.frontend_ami_west.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer_west.key_name
  vpc_security_group_ids = [aws_security_group.frontend_ec2_dr.id]
  user_data              = base64encode(local.user_data_frontend)
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "backend_lt_west" {
  provider               = aws.secondary
  name_prefix            = "lt-backend-west-"
  image_id               = aws_ami_from_instance.backend_ami_west.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer_west.key_name
  vpc_security_group_ids = [aws_security_group.backend_ec2_dr.id]
  user_data              = base64encode(local.user_data_backend)
  lifecycle {
    create_before_destroy = true
  }
}


