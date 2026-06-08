# W8 Challenge (W9-ready) — K8s on AWS, Terraform 1-Click

Dung EC2 bang Terraform -> chay **kind hoac minikube** trong EC2 -> deploy **platform 3-component**
(frontend/api/worker) trong cum -> frontend expose qua **ALB**. Mot lenh dung tat ca; 3 provider (`aws`+`tls`+`local`).

> **W9-ready:** truoc deploy 1 app `web`; gio deploy **3-component** (k8s/platform.yaml) -> chinh la "diem xuat phat W9".
> Tai su dung CUM NAY cho ca W9 (cai ArgoCD/Observability/Canary len tren). Thieu gi them nay.

## Kien truc
```
Browser -> ALB :80 -> target group -> EC2:30080 (host)
        -> NodePort 30080 -> Service frontend -> Pod frontend :80 (nginxdemos/hello)
   trong cum con co: api (HPA+graceful), worker, NetworkPolicy
```
- "Ngoai cum" (aws provider): ALB, EC2, SG.  "Trong cum": Service NodePort, 3-component.
- Wire provider: `tls.private_key` -> `aws_key_pair` + `local_file` (.pem de SSH).
- `cluster_tool` = `kind` (mac dinh) hoac `minikube` (--driver=none). Ai dung gi o W8 giu nguyen, KHONG phai doi.

## File
| File | Vai tro |
|---|---|
| `versions.tf` | khai bao + pin 3 provider |
| `variables.tf` | bien (region, profile, instance_type=t3.large, cluster_tool, node_port=30080) |
| `network.tf` | VPC default + 2 Security Group (ALB / EC2) |
| `compute.tf` | tls key + EC2 + bootstrap (inject k8s/platform.yaml qua base64) |
| `userdata-kind.sh.tftpl` / `userdata-minikube.sh.tftpl` | cai docker/cluster/kubectl + deploy 3-component |
| `k8s/platform.yaml` | **3-component** (frontend/api/worker + HPA + NetworkPolicy) = source cho GitOps W9 |
| `alb.tf` | ALB + target group + listener (tro vao frontend) |
| `outputs.tf` | app_url, ssh_command, ... |

## CACH CHAY

> ⚠️ Tao tai nguyen AWS THAT (EC2 + ALB) -> TON TIEN. Dung account KHONG phai prod (730335527901). Destroy ngay sau khi xong.

```bash
# 0) Login account sandbox + xac nhan KHONG phai prod
aws sso login --profile AdministratorAccess-025066280037
export AWS_PROFILE=AdministratorAccess-025066280037
aws sts get-caller-identity            # Account phai != 730335527901

# 1) Khoa SSH ve IP cua ban + chon region
export TF_VAR_allowed_ssh_cidr="$(curl -s ifconfig.me)/32"
export TF_VAR_region="ap-southeast-1"
export TF_VAR_aws_profile="$AWS_PROFILE"

# 2) Dung (1-click)
terraform init
terraform plan        # DOC ky: chi EC2 + ALB + SG + key
terraform apply -auto-approve

# 3) Lay URL (doi ~2-3 phut cho app len -> target unhealthy roi healthy)
terraform output app_url
```

## NGHIEM THU
```bash
# App mo duoc qua ALB
curl -s "$(terraform output -raw app_url)" | head

# Target healthy chua
aws elbv2 describe-target-health \
  --target-group-arn "$(terraform output -raw target_group_arn)" \
  --query 'TargetHealthDescriptions[].TargetHealth.State' --output text

# Chung minh 3-component chay TRONG K8s
ssh -i w8-key.pem ubuntu@$(terraform output -raw ec2_public_ip) 'sudo kubectl -n demo get pods,svc,hpa'
# -> thay frontend/api/worker + svc frontend NodePort 30080 + hpa api

# Debug 502 (neu co): cloud-init xong chua
ssh -i w8-key.pem ubuntu@$(terraform output -raw ec2_public_ip) 'cat /root/ready; sudo tail -50 /var/log/cloud-init-output.log'
```

## TIEN THANG SANG W9 (dung lai cum nay)
```bash
# Commit platform lam source-of-truth cho GitOps (D1):
scp -i w8-key.pem -r ubuntu@$(terraform output -raw ec2_public_ip):/root/platform.yaml ./   # hoac dung k8s/platform.yaml san co
# Truy cap UI cac tool W9 (ArgoCD/Grafana...) qua SSH tunnel, vd:
#   ssh -i w8-key.pem -L 8080:localhost:8080 ubuntu@<ip>
#   (tren EC2) sudo kubectl -n argocd port-forward svc/argocd-server 8080:443
```
> W9 KHONG can ALB (truy cap qua tunnel). ALB giu lai cung duoc (la deliverable W8).
> Luu y RAM: W9 cai them ArgoCD+Prometheus+Loki+Rollouts -> dung **t3.large (8GB) tro len** (da set mac dinh).

## TIET KIEM TIEN (quan trong)
```bash
# STOP khi khong dung (chi tra tien gio chay; EBS giu nguyen, start lai sau):
aws ec2 stop-instances  --instance-ids $(terraform output -raw ec2_instance_id) --profile $AWS_PROFILE
aws ec2 start-instances --instance-ids $(terraform output -raw ec2_instance_id) --profile $AWS_PROFILE
# Xong han -> xoa sach:
terraform destroy -auto-approve
```
> Bo ALB de re hon nua: W9 khong dung ALB -> co the comment alb.tf neu chi can hoc W9.

> Giai thich sau + 9 cau hoi cham: xem `../../W9/W8-challenge-terraform-1click.md`.
