
# east
resource "aws_ami_from_instance" "frontend_ami_east" {
  provider                = aws.primary
  name                    = "img-frontend-east-${local.ami_timestamp}"
  source_instance_id      = aws_instance.frontend_east.id
  snapshot_without_reboot = true
}

resource "aws_ami_from_instance" "backend_ami_east" {
  provider                = aws.primary
  name                    = "img-backend-east-${local.ami_timestamp}"
  source_instance_id      = aws_instance.backend_east.id
  snapshot_without_reboot = true
}

# west
resource "aws_ami_from_instance" "frontend_ami_west" {
  provider                = aws.secondary
  name                    = "img-frontend-west-${local.ami_timestamp}"
  source_instance_id      = aws_instance.frontend_west.id
  snapshot_without_reboot = true
}

resource "aws_ami_from_instance" "backend_ami_west" {
  provider                = aws.secondary
  name                    = "img-backend-west-${local.ami_timestamp}"
  source_instance_id      = aws_instance.backend_west.id
  snapshot_without_reboot = true
}
