resource "aws_key_pair" "nvme_demo" {
  key_name   = var.name_prefix
  public_key = var.ssh_public_key
}
