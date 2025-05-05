terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    external = {
      source = "hashicorp/external"
    }
  }
}

provider "aws" {
  alias  = "default"
  region = "ap-northeast-1" # 默认region，可被动态覆盖
}

# 1. 读取配置文件
# 需要本地脚本将config.yaml转为Terraform可用的JSON格式
# 这里假设有一个external data source脚本 parse_config.py

data "external" "config" {
  program = ["python3", "parse_config.py", var.config_file]
}

locals {
  accounts = jsondecode(data.external.config.result["accounts"])
  instance_map = merge([
    for acc in local.accounts : merge([
      for reg in acc["regions"] : merge([
        for subnet in reg["subnets"] : merge([
          for i in range(subnet["instance_count"]) : {
            "${acc["account_id"]}_${reg["region"]}_${subnet["subnet_id"]}_instance${i}" = {
              account_id = acc["account_id"]
              region     = reg["region"]
              subnet_id  = subnet["subnet_id"]
              idx        = i
            }
          }
        ]...)
      ]...)
    ]...)
  ]...)
}

# 2. 自动生成密钥对（如无）
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key" {
  content         = tls_private_key.ec2_key.private_key_pem
  filename        = "id_rsa"
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content         = tls_private_key.ec2_key.public_key_openssh
  filename        = "id_rsa.pub"
  file_permission = "0644"
}

resource "aws_key_pair" "generated" {
  key_name   = var.key_name
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# 3. 自动查找Ubuntu AMI
# 以ap-northeast-1为例，实际应对每个region查找
# 这里用for_each动态处理

data "aws_ami" "ubuntu" {
  for_each = toset(flatten([
    for acc in local.accounts : [for reg in acc["regions"] : reg["region"]]
  ]))
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  provider = aws
}

# 4. 创建带SSM权限的EC2实例
resource "aws_iam_role" "ssm" {
  name = "ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ssm.name
}

resource "aws_instance" "test" {
  for_each                    = local.instance_map
  ami                         = data.aws_ami.ubuntu[each.value.region].id
  instance_type               = var.instance_type
  subnet_id                   = each.value.subnet_id
  key_name                    = aws_key_pair.generated.key_name
  iam_instance_profile        = aws_iam_instance_profile.ssm.name
  user_data                   = file("bootstrap.sh")
  associate_public_ip_address = true
  tags = {
    Name      = "multi-account-ec2-test"
    AccountId = each.value.account_id
    Region    = each.value.region
    Index     = each.value.idx
  }
  provider = aws.default # 实际应为动态provider alias，简化处理
}
