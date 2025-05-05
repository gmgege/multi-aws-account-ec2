# 多账号多区域EC2网络连通性测试自动化部署

本项目通过Terraform在多个AWS账号、指定region和子网中自动部署用于网络连通性和路由测试的EC2实例。

## 功能特性
- 支持多账号、多区域、多子网批量部署EC2
- 所有配置集中于`config.yaml`
- 自动生成SSH密钥对（如无）
- EC2实例支持SSM Session Manager无密钥登录
- 自动查找最新Ubuntu官方AMI
- 启动自动安装网络测试工具（iperf3、traceroute等）
- 一键销毁所有资源

## 目录结构
```
├── bootstrap.sh         # EC2初始化脚本
├── config.yaml          # 多账号多区域配置文件
├── main.tf              # Terraform主配置
├── outputs.tf           # 输出定义
├── variables.tf         # 变量定义
├── README.md            # 项目说明
```

## 快速开始
### 1. 配置AWS凭证
建议使用[aws-vault](https://github.com/99designs/aws-vault)或`aws configure`，并确保有足够权限。

### 2. 编辑配置文件
根据实际情况编辑`config.yaml`，示例：
```yaml
accounts:
  - account_id: "111111111111"
    regions:
      - region: "ap-northeast-1"
        subnets:
          - subnet_id: "subnet-xxxxxx1"
            instance_count: 1
```

### 3. 初始化与部署
```sh
terraform init
terraform apply -auto-approve
```
首次运行会自动生成密钥对（id_rsa/id_rsa.pub），并创建EC2实例。

### 4. 登录与测试
- 推荐使用AWS Console的Session Manager直接登录EC2，无需密钥。
- 也可用生成的私钥SSH登录（如安全组允许）。
- 实例已预装iperf3、traceroute、curl等工具。

### 5. 查看输出
`terraform output ec2_instance_info` 可查看所有实例的ID、IP、region等信息。

### 6. 一键销毁
```sh
terraform destroy -auto-approve
```

## 注意事项
- 建议所有资源加上`Name`标签，便于统一管理和销毁。
- 若需跨账号自动切换，建议结合[aws-vault](https://github.com/99designs/aws-vault)或自定义provider alias。
- `parse_config.py`需将config.yaml转为Terraform可用的JSON格式（可用PyYAML实现）。

## 进阶用法
- 可扩展支持更多测试工具或自定义AMI。
- 可按需调整实例类型、数量、子网等参数。

---
如有问题欢迎反馈！ 