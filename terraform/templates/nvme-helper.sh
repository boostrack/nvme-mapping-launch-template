#!/bin/bash

set -e

function mount_nvme() {
    aws_block_device=$1
    mount_point=$2
    fs_type=$3

    instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

    export AWS_DEFAULT_REGION=${aws_region}
    aws sts get-caller-identity

    until [ ! -z "$aws_volume_id" ]; do
        aws_volume_id=$(aws ec2 describe-volumes \
            --filters Name=attachment.instance-id,Values=$instance_id Name=attachment.device,Values=$aws_block_device \
            --query 'Volumes[*].{Volume:Attachments[0].VolumeId,State:Attachments[0].State}' \
            --output json | jq -r '.[]? | select(.State | contains("attached")) .Volume')

        echo "waiting for $aws_block_device volume to be attached..."
        sleep 5
    done

    echo "set $aws_volume_id volume to nvme compliant format"
    nvme_volume_id=vol$(echo $aws_volume_id | cut -c5-)
    nvme_block_devices=$(nvme list -o json | jq -r '.Devices | .[]? | .DevicePath')

    for nvme_block_device in $nvme_block_devices; do
        if [[ $nvme_volume_id == $(nvme id-ctrl -v -o json $nvme_block_device | jq -r .sn) ]]; then
            echo "found matching block for $nvme_volume_id: $nvme_block_device"
            if [ ! -L "$aws_block_device" ]; then
                echo "symlink alias $aws_block_device to block $nvme_block_device"
                ln -s $nvme_block_device $aws_block_device

                echo "create a $fs_type file system for $aws_block_device"
                mkfs -t $fs_type $aws_block_device
                mkdir -p $mount_point

                echo "get volume uuid and mount it to $mount_point"
                volume_uuid=$(blkid -s UUID -o value $aws_block_device)
                mount UUID="$volume_uuid" $mount_point

                echo "add $volume_uuid to fstab"
                cp /etc/fstab /etc/fstab.orig
                echo "UUID="$volume_uuid" $mount_point $fs_type defaults,nofail  0  2" | tee -a /etc/fstab
            fi

            return
        fi
    done
}
