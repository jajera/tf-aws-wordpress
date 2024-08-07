#!/bin/bash -x

FILE_SYSTEM_ID=$1
DATA_DIRECTORY=$2
GROWTH=$3
COPY_SYSTEM_ID=$4
WP_DIR=$5

if [ $# -lt 3 ]; then
  echo "Invalid # of arguments. Require: file system id, data directory, file system growth (GiB) "
  exit 0
fi

# get region from instance meta-data
availabilityzone=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
region=${!availabilityzone:0:-1}

# get instance id
instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# get autoscaling group name
asg_name=$(aws autoscaling describe-auto-scaling-instances --instance-ids $instance_id --region $region --output text --query 'AutoScalingInstances[0].AutoScalingGroupName')

# set the number of threads to the number of vcpus
threads=$(( $(nproc --all) * 8 ))

# wait for file system DNS name to be propagated
results=1
while [[ $results != 0 ]]; do
  nslookup $FILE_SYSTEM_ID.efs.$region.amazonaws.com
  results=$?
  if [[ results = 1 ]]; then
    sleep 30
  fi
done

# mount file system
sudo mkdir -p /$FILE_SYSTEM_ID
sudo chown ec2-user:ec2-user /$FILE_SYSTEM_ID
sudo mountpoint -q /$FILE_SYSTEM_ID || sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $FILE_SYSTEM_ID.efs.$region.amazonaws.com:/ /$FILE_SYSTEM_ID

# create directory if not exists
sudo mkdir -p /$FILE_SYSTEM_ID/$DATA_DIRECTORY
sudo chown ec2-user:ec2-user /$FILE_SYSTEM_ID/$DATA_DIRECTORY

# dd 1GiB files to file system to match DATA_SIZE
files=$GROWTH
if [ $(( $files / $threads )) == 0 ];
  then
    runs=0
    parallel_threads=$(( $files % $threads ))
  else
    runs=$(( $files / $threads ))
    parallel_threads=$threads
fi
while [ $runs -ge 0 ]; do
  if [ $runs == 0 ];
    then
      parallel_threads=$(( $files % $threads ))
      seq 0 $(( $parallel_threads - 1 )) | parallel --will-cite -j $parallel_threads --compress dd if=/dev/zero of=/$FILE_SYSTEM_ID/$DATA_DIRECTORY/1G-dd-$(date +%Y%m%d%H%M%S.%3N)-{} bs=1M count=1024 oflag=sync
      runs=$(($runs-1))
    else
      seq 0 $(( $parallel_threads - 1 )) | parallel --will-cite -j $parallel_threads --compress dd if=/dev/zero of=/$FILE_SYSTEM_ID/$DATA_DIRECTORY/1G-dd-$(date +%Y%m%d%H%M%S.%3N)-{} bs=1M count=1024 oflag=sync
      runs=$(($runs-1))
  fi
done

#Sync data from

if [[ ! -z $COPY_SYSTEM_ID ]];
  then
    sudo mkdir -p /$COPY_SYSTEM_ID
    sudo chown ec2-user:ec2-user /$COPY_SYSTEM_ID
    sudo mountpoint -q /$COPY_SYSTEM_ID || sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $COPY_SYSTEM_ID.efs.$region.amazonaws.com:/ /$COPY_SYSTEM_ID
    COPY_SOURCE=/$COPY_SYSTEM_ID
    if [ -d "/$COPY_SOURCE/$WP_DIR" ]; then
      COPY_SOURCE=/$COPY_SYSTEM_ID/$WP_DIR #If the wordpress folder is there, ensure we get only the contents
    fi
    sudo mkdir -p /$FILE_SYSTEM_ID/$WP_DIR
    sudo rsync -r $COPY_SOURCE/* /$FILE_SYSTEM_ID/$WP_DIR/
fi

# set ASG to zero which terminates instance
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $asg_name --desired-capacity 0 --region $region
