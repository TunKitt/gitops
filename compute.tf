# provider #2 (tls): sinh khoa, wire sang aws_key_pair (#1) va local_file (#3)
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh" {
  key_name   = "${var.name}-key"
  public_key = tls_private_key.ssh.public_key_openssh # WIRE: tls output -> aws input
}

resource "local_file" "pem" {
  content         = tls_private_key.ssh.private_key_pem # WIRE: tls output -> file
  filename        = "${path.module}/${var.name}-key.pem"
  file_permission = "0400"
}

resource "aws_instance" "node" {
  ami                         = data.aws_ssm_parameter.ubuntu.value
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  key_name                    = aws_key_pair.ssh.key_name
  associate_public_ip_address = true

  # bootstrap: chon kind hoac minikube qua var.cluster_tool + deploy platform 3-component (W9-ready)
  user_data = templatefile("${path.module}/userdata-${var.cluster_tool}.sh.tftpl", {
    node_port    = var.node_port
    platform_b64 = base64encode(file("${path.module}/k8s/platform.yaml"))
  })

  root_block_device {
    volume_size = 30 # W9 cai them stack (ArgoCD/Prometheus/Loki/Rollouts) -> 30GB
    volume_type = "gp3"
  }

  tags = { Name = "${var.name}-node" }
}
