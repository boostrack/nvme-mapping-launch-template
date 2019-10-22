locals {
  iam_name_prefix = replace(var.name_prefix, "-", "_")

  iam_policies = [
    aws_iam_policy.ec2_vol_ro.arn,
  ]
}
