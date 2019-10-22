aws_region              = "eu-west-1"
vpc_id                  = "vpc-..."
subnets                 = ["subnet-..."]
ssh_public_key          = "ssh-rsa AAAAB3..."

name_prefix             = "nvme-demo"
ssh_allowed_cidr_blocks = ["0.0.0.0/0"]

block_device_mappings = [
  {
    device_name = "/dev/xvda"
    mount_point = "/data"
    fs_type     = "xfs"

    ebs = {
      volume_size           = 15
      volume_type           = "gp2"
      delete_on_termination = true
      encrypted             = false
    }
  },
  {
    device_name = "/dev/xvdb"
    mount_point = "/uploads"
    fs_type     = "xfs"

    ebs = {
      volume_size           = 30
      volume_type           = "gp2"
      delete_on_termination = true
      encrypted             = true
    }
  },
]

tags = {
  Terraform   = "true"
  Environment = "test"
}
