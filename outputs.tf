output "ec2_instance_info" {
  description = "所有EC2实例的关键信息"
  value = {
    for instance in aws_instance.test :
    instance.id => {
      account_id = instance.tags["AccountId"]
      region     = instance.availability_zone
      subnet_id  = instance.subnet_id
      private_ip = instance.private_ip
      public_ip  = instance.public_ip
    }
  }
} 
