
resource "aws_security_group" "nvme_demo" {
  name        = format("%s-asg", var.name_prefix)
  description = format("Security group for the %s instances", var.name_prefix)

  vpc_id = var.vpc_id

  # tmp
  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22

    cidr_blocks = var.ssh_allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    map("Name", format("%s", var.name_prefix)),
  )
}
