import boto3
import os
import sys

def handler(event, context):
    if not os.environ.get('filesystemid'):
        print "Unable to get the environment variable filesystemid"
        sys.exit(1)
    else:
        filesystemid = os.environ.get('filesystemid')

    if not os.environ.get('region'):
        print "Unable to get the environment variable region"
        sys.exit(1)
    else:
        region = os.environ.get('region')

    def efs_get_size():
        client = boto3.client('efs')
        response = client.describe_file_systems(FileSystemId=filesystemid)
        k = response['FileSystems'][0]['SizeInBytes']['Value']
        return k

    def cloudwatch_put_metric():
        client = boto3.client('cloudwatch')
        client.put_metric_data(
            MetricData=[
                {
                    'MetricName': 'SizeInBytes',
                    'Dimensions': [
                        {
                            'Name': 'FileSystemId',
                            'Value': filesystemid
                        },
                    ],
                    'Unit': 'None',
                    'Value': efs_get_size()
                },
            ],
            Namespace='Custom/EFS'
        )
        print('CloudWatch metric SizeInBytes sucessfully updated.')

    cloudwatch_put_metric()
