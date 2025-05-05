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

本项目支持通过AWS CLI profile指定身份：
- 推荐方式：
  ```sh
  terraform apply -var="aws_profile=your_profile_name"
  ```
- 或通过环境变量：
  ```sh
  export AWS_PROFILE=your_profile_name
  terraform apply
  ```

### 2. 编辑配置文件
根据实际情况编辑`