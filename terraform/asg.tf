data "template_cloudinit_config" "nvme_demo" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "terraform.tpl"
    content_type = "text/cloud-config"

    content = templatefile(format("%s/templates/init", path.root), {
      nvme_helper_content = base64encode(templatefile(format("%s/templates/nvme-helper.sh", path.root), {
        aws_region = var.aws_region
      }))
    })
  }

  dynamic "part" {
    for_each = var.block_device_mappings
    iterator = block_device

    content {
      content_type = "text/x-shellscript"

      content = templatefile(format("%s/templates/mount-nvme.sh", path.module), {
        aws_block_device = lookup(block_device.value, "device_name")
        mount_point      = lookup(block_device.value, "mount_point")
        fs_type          = lookup(block_device.value, "fs_type")
      })
    }
  }
}

resource "aws_launch_template" "nvme_demo" {
  name_prefix = format("%s-", var.name_prefix)

  image_id      = data.aws_ami.nvme_demo.id
  instance_type = "t3.nano"
  key_name      = aws_key_pair.nvme_demo.key_name
  user_data     = base64encode(data.template_cloudinit_config.nvme_demo.rendered)

  iam_instance_profile {
    name = aws_iam_instance_profile.nvme_demo.name
  }

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    iterator = block_device

    content {
      device_name = lookup(block_device.value, "device_name", null)

      dynamic "ebs" {
        for_each = flatten(list(lookup(block_device.value, "ebs", [])))

        content {
          volume_size           = lookup(ebs.value, "volume_size", null)
          volume_type           = lookup(ebs.value, "volume_type", null)
          delete_on_termination = lookup(ebs.value, "delete_on_termination", null)
          encrypted             = lookup(ebs.value, "encrypted", null)
        }
      }
    }
  }

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = true
    delete_on_termination       = true

    security_groups = [aws_security_group.nvme_demo.id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags,
      map("Name", format("%s", var.name_prefix))
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      var.tags,
      map("Name", format("%s", var.name_prefix)),
    )
  }

  tags = merge(
    var.tags,
    map("Name", format("%s", var.name_prefix))
  )
}

resource "aws_autoscaling_group" "nvme_demo" {
  name_prefix          = format("%s-", var.name_prefix)
  vpc_zone_identifier  = var.subnets
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  termination_policies = ["OldestInstance"]

  launch_template {
    id      = aws_launch_template.nvme_demo.id
    version = aws_launch_template.nvme_demo.latest_version
  }

  health_check_type         = "ELB"
  health_check_grace_period = 180
  wait_for_capacity_timeout = "5m"

  tag {
    key                 = "Name"
    value               = format("%s", var.name_prefix)
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
