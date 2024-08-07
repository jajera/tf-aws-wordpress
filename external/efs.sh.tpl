#!/bin/bash -xe

yum update -y
yum --enablerepo=epel install nload -y
ntpstat

aws s3 cp s3://${S3_BUCKET}/scripts/efs-add-storage.sh /tmp/efs-add-storage.sh
chmod +x /tmp/efs-add-storage.sh
sh /tmp/efs-add-storage.sh ${FILE_SYSTEM_ID} ${DATA_DIRECTORY} ${GROWTH} ${COPY_SYSTEM_ID} ${WP_DIR}
