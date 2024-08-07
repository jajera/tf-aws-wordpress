#!/bin/bash -xe

yum update -y
yum --enablerepo=epel install nload -y
ntpstat

aws s3 cp s3://${S3_BUCKET}/scripts/set-cloudwatch-alarms.sh /tmp/set-cloudwatch-alarms.sh
chmod +x /tmp/set-cloudwatch-alarms.sh
sh /tmp/set-cloudwatch-alarms.sh ${FILE_SYSTEM_ID} ${WARNING_THRESHOLD_MINUTES} ${CRITICAL_THRESHOLD_MINUTES} ${SNS_ARN}
