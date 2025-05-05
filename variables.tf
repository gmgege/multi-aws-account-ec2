variable "config_file" {
  description = "配置文件路径"
  type        = string
  default     = "config.yaml"
}

variable "key_name" {
  description = "EC2密钥对名称"
  type        = string
  default     = "multi-account-ec2-key"
}

variable "instance_type" {
  description = "EC2实例类型"
  type        = string
  default     = "t3.micro"
} 
