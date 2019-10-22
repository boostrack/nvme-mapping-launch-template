data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_vol_ro" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeVolumeAttribute",
      "ec2:DescribeVolumeStatus",
      "ec2:DescribeVolumes"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_vol_ro" {
  name        = format("%s_ec2_vol_read_only", local.iam_name_prefix)
  description = "allow read only access to ec2 volumes"
  policy      = data.aws_iam_policy_document.ec2_vol_ro.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "nvme_demo" {
  name               = format("%s", local.iam_name_prefix)
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_instance_profile" "nvme_demo" {
  name = format("%s", local.iam_name_prefix)
  path = "/"
  role = aws_iam_role.nvme_demo.name
}

resource "aws_iam_role_policy_attachment" "attached_policies" {
  count      = length(local.iam_policies)
  role       = aws_iam_role.nvme_demo.name
  policy_arn = local.iam_policies[count.index]
}
