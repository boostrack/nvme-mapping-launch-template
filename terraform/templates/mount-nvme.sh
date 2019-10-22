#!/bin/bash

set -e

source /usr/bin/nvme-helper.sh
mount_nvme ${aws_block_device} ${mount_point} ${fs_type}
