#!/bin/sh -x

FILE_SYSTEM_ID=$1
WARNING_THRESHOLD_MINUTES=$2
CRITICAL_THRESHOLD_MINUTES=$3
SNS_ARN=$4

error=0

# Get region
availability_zone=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
region=$(echo "$availability_zone" | sed 's/.$//')

# Get instance ID
instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Get autoscaling group name
asg_name=$(aws autoscaling describe-auto-scaling-instances --instance-ids "$instance_id" --region "$region" --output text --query 'AutoScalingInstances[0].AutoScalingGroupName')

# Get autoscaling policy ARN
asg_policy_arn=$(aws autoscaling describe-policies --auto-scaling-group-name "$asg_name" --region "$region" --output text --query 'ScalingPolicies[0].PolicyARN')

# Validate FILE_SYSTEM_ID; send notification and exit if it doesn't exist
aws efs describe-file-systems --file-system-id "$FILE_SYSTEM_ID" --region "$region" --output text --query 'FileSystems[0].[FileSystemId]'
result=$?
if [ $result -ne 0 ]; then
   aws sns publish --topic-arn "$SNS_ARN" --region "$region" --message "Amazon EFS burst credit balance CloudWatch alarm error. File system $FILE_SYSTEM_ID does not exist."
   exit 1
fi

# Get current permitted throughput
count=1
while [ -z "$permitted_throughput" ] || [ "$permitted_throughput" = "null" ] && [ $count -lt 60 ]; do
   permitted_throughput=$(aws cloudwatch get-metric-statistics --namespace AWS/EFS --metric-name PermittedThroughput --dimensions Name=FileSystemId,Value="$FILE_SYSTEM_ID" --start-time $(date --utc +%FT%TZ -d '-120 seconds') --end-time $(date --utc +%FT%TZ -d '-60 seconds') --period 60 --statistics Sum --region "$region" --output json --query 'Datapoints[0].Sum')
   sleep 2
   count=$(expr $count + 1)
done

# Get current burst credit balance
count=1
while [ -z "$burst_credit_balance" ] || [ "$burst_credit_balance" = "null" ] && [ $count -lt 60 ]; do
   burst_credit_balance=$(aws cloudwatch get-metric-statistics --namespace AWS/EFS --metric-name BurstCreditBalance --dimensions Name=FileSystemId,Value="$FILE_SYSTEM_ID" --start-time $(date --utc +%FT%TZ -d '-120 seconds') --end-time $(date --utc +%FT%TZ -d '-60 seconds') --period 60 --statistics Sum --region "$region" --output json --query 'Datapoints[0].Sum')
   sleep 2
   count=$(expr $count + 1)
done

# Calculate new burst credit balance warning threshold
burst_credit_balance_threshold_warning=$(expr ${burst_credit_balance} - ( ( ( ${burst_credit_balance} / ( ${permitted_throughput} * 60 ) ) - $WARNING_THRESHOLD_MINUTES ) * ( ${permitted_throughput} * 60 ) ))

# Calculate new burst credit balance critical threshold
burst_credit_balance_threshold_critical=$(expr ${burst_credit_balance} - ( ( ( ${burst_credit_balance} / ( ${permitted_throughput} * 60 ) ) - $CRITICAL_THRESHOLD_MINUTES ) * ( ${permitted_throughput} * 60 ) ))

# Update warning alarm with new burst credit balance warning threshold
aws cloudwatch put-metric-alarm --alarm-name "${FILE_SYSTEM_ID} burst credit balance - Warning - StackName" --alarm-description "${FILE_SYSTEM_ID} burst credit balance - Warning - StackName" --actions-enabled --alarm-actions "$SNS_ARN" --metric-name BurstCreditBalance --namespace AWS/EFS --statistic Sum --dimensions Name=FileSystemId,Value="$FILE_SYSTEM_ID" --period 60 --evaluation-periods 5 --threshold "$burst_credit_balance_threshold_warning" --comparison-operator LessThanThreshold --treat-missing-data missing --region "$region"
result=$?
if [ $result -ne 0 ]; then
   aws sns publish --topic-arn "$SNS_ARN" --region "$region" --message "Amazon EFS burst credit balance CloudWatch alarm error. Check CloudWatch alarms for file system $FILE_SYSTEM_ID."
   error=$(expr $error + 1)
fi

# Update critical alarm with new burst credit balance critical threshold
aws cloudwatch put-metric-alarm --alarm-name "${FILE_SYSTEM_ID} burst credit balance - Critical - StackName" --alarm-description "${FILE_SYSTEM_ID} burst credit balance - Critical - StackName" --actions-enabled --alarm-actions "$SNS_ARN" --metric-name BurstCreditBalance --namespace AWS/EFS --statistic Sum --dimensions Name=FileSystemId,Value="$FILE_SYSTEM_ID" --period 60 --evaluation-periods 5 --threshold "$burst_credit_balance_threshold_critical" --comparison-operator LessThanThreshold --treat-missing-data missing --region "$region"
result=$?
if [ $result -ne 0 ]; then
   aws sns publish --topic-arn "$SNS_ARN" --region "$region" --message "Amazon EFS burst credit balance CloudWatch alarm error. Check CloudWatch alarms for file system $FILE_SYSTEM_ID."
   error=$(expr $error + 1)
fi

# Update burst credit balance increase threshold
aws cloudwatch put-metric-alarm --alarm-name "Set ${FILE_SYSTEM_ID} burst credit balance increase threshold - StackName" --alarm-description "Set ${FILE_SYSTEM_ID} burst credit balance increase threshold - StackName" --actions-enabled --alarm-actions "$SNS_ARN" "$asg_policy_arn" --metric-name PermittedThroughput --namespace AWS/EFS --statistic Sum --dimensions Name=FileSystemId,Value="$FILE_SYSTEM_ID" --period 60 --evaluation-periods 5 --threshold "$permitted_throughput" --comparison-operator GreaterThanThreshold --treat-missing-data missing --region "$region"
result=$?
if [ $result -ne 0 ]; then
   aws sns publish --topic-arn "$SNS_ARN" --region "$region" --message "Amazon EFS burst credit balance CloudWatch alarm error. Check CloudWatch alarms for file system $FILE_SYSTEM_ID."
   error=$(expr $error + 1)
fi

# Update burst credit balance decrease threshold
aws cloudwatch put-metric-alarm --alarm-name "Set ${FILE_SYSTEM_ID} burst credit balance decrease threshold - StackName" --alarm-description "Set ${FILE_SYSTEM_ID} burst credit balance decrease threshold - StackName" --actions-enabled --alarm-actions "$SNS_ARN" "$asg_policy_arn" --metric-name PermittedThroughput --namespace AWS/EFS --statistic Sum --dimensions Name=FileSystemId,Value="$FILE_SYSTEM_ID" --period 60 --evaluation-periods 5 --threshold "$permitted_throughput" --comparison-operator LessThanThreshold --treat-missing-data missing --region "$region"
result=$?
if [ $result -ne 0 ]; then
   aws sns publish --topic-arn "$SNS_ARN" --region "$region" --message "Amazon EFS burst credit balance CloudWatch alarm error. Check CloudWatch alarms for file system $FILE_SYSTEM_ID."
   error=$(expr $error + 1)
fi

# Auto terminate instance - setting auto scaling group desired capacity to 0
if [ $error -eq 0 ]; then
   aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$asg_name" --desired-capacity 0 --region "$region"
else
   aws sns publish --topic-arn "$SNS_ARN" --region "$region" --message "Amazon EFS burst credit balance CloudWatch alarm error. Check CloudWatch alarms for file system $FILE_SYSTEM_ID."
fi
