variable "region" {
  description = "AWS region (chon region tach biet prod)"
  type        = string
  default     = "ap-southeast-1"
}

variable "instance_type" {
  description = "EC2 size. W8 single-app: t3.medium du. W9 (them ArgoCD/Prometheus/Loki/Rollouts): dung t3.large (8GB) tro len"
  type        = string
  default     = "t3.large"
}

variable "allowed_ssh_cidr" {
  description = "CIDR duoc SSH vao EC2 - DAT = IP cua ban (vd 1.2.3.4/32)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "node_port" {
  description = "NodePort ma kind map ra host EC2, ALB tro toi cong nay"
  type        = number
  default     = 30080
}

variable "name" {
  description = "Tien to dat ten tai nguyen"
  type        = string
  default     = "w8"
}

variable "cluster_tool" {
  description = "Cong cu dung cum trong EC2: 'kind' (khuyen nghi) hoac 'minikube' (--driver=none)"
  type        = string
  default     = "kind"
  validation {
    condition     = contains(["kind", "minikube"], var.cluster_tool)
    error_message = "cluster_tool chi nhan 'kind' hoac 'minikube'."
  }
}
