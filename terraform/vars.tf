variable "aws_region" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "block_device_mappings" {
  type = list(object({
    device_name = string
    mount_point = string
    fs_type     = string

    ebs = object({
      volume_size           = number
      volume_type           = string
      delete_on_termination = bool
      encrypted             = bool
    })
  }))
}

variable "ssh_public_key" {
  type = string
}

variable "ssh_allowed_cidr_blocks" {
  type = list
}

variable "tags" {
  type = map
}
