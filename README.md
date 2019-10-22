# NVMe Mapping Launch Template

An fully working implemention of the following [blog post](https://www.laurentgodet.com/2019/10/ebs-nvme-block-device-mapping-using-volume-ids/), which describes how to automatically map and mount all EBS NVMe Block Devices to their corresponding standards paths on boot time, using Volume IDs.

This terraform code sample includes:
- Autoscallng group and Launch Template 
- Cloud Init userdata scripts to do the heavy lifting
- IAM policies required to perform the mapping

## Instructions

Generate an ssh key
```bash
$ ssh-keygen -t rsa -f ~/.ssh/nvme-demo -C "nvme demo"
```

Replace the dummy values in `values.tfvars` with your own.
```bash
$ cd terraform

$ cat values.tfvars
aws_region              = "..."
vpc_id                  = "vpc-..."
subnets                 = ["subnet-..."]
ssh_public_key          = "ssh-rsa AAAAB3..."
```

Apply changes
```bash
$ terraform init

$ terraform apply -var-file=values.tfvars
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
```

Connect on the ec2 instance
```bash
$ instance_ip=$(aws ec2 describe-instances \
    --filters Name=tag:Name,Values=nvme-demo | \
    jq -r '.Reservations[0].Instances[0].PublicIpAddress')

$ ssh -i ~/.ssh/nvme-demo ubuntu@$instance_ip
```

As expected, all volumes are correctly mounted
```bash
ec2:~$ mount | grep nvme
/dev/nvme2n1p1 on /        type ext4 (rw,relatime,discard,data=ordered)
/dev/nvme0n1   on /data    type xfs  (rw,relatime,attr2,inode64,noquota)
/dev/nvme1n1   on /uploads type xfs  (rw,relatime,attr2,inode64,noquota)

ec2:~$ df -h | grep nvme
Filesystem      Size  Used Avail Use% Mounted on
/dev/nvme2n1p1  7.7G  1.3G  6.5G  17% /
/dev/nvme0n1     15G   48M   15G   1% /data
/dev/nvme1n1     30G   63M   30G   1% /uploads
```
