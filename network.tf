# Dung VPC + subnet mac dinh (ALB can >=2 AZ -> default subnets trai nhieu AZ)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# AMI Ubuntu 22.04 moi nhat (lay qua SSM public parameter, khong hardcode AMI id)
data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

# SG cho ALB: nhan :80 tu Internet
resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  description = "ALB ingress 80 from internet"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle { create_before_destroy = true }
}

# SG cho EC2: nhan NodePort CHI tu ALB, SSH chi tu IP ban
resource "aws_security_group" "ec2" {
  name_prefix = "${var.name}-ec2-"
  description = "EC2 nodeport from ALB + ssh from me"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "NodePort tu ALB"
    from_port       = var.node_port
    to_port         = var.node_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # chi ALB, khong phai ca Internet
  }
  ingress {
    description = "SSH debug"
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
  lifecycle { create_before_destroy = true }
}
