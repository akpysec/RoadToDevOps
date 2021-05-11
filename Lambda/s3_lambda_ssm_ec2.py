# Prerequisites - SSM agent on ec2-instance installed
# https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-manual-agent-install.html

# EC2 Instance role attached with SSM permissions
# Lambda permissions:
# AmazonEC2ReadOnlyAccess - for running command retrieval
# AmazonSSMFullAccess - for SSM (can be narrowed down to more specific permissions)
# AWSLambdaExecute - for Lambda Executions

# Imported Libraries
import time
import json
import boto3

# Specify handler - s3_lambda_ssm_ec2.lambda_handler
def lambda_handler(event, context):
    
    # Client Variables assignment
    client = boto3.client('ec2')
    ssm = boto3.client('ssm')
    
    # Copy - Paste-in instance ID
    Instance_ID = ''
    
    # Execute command through SSM to EC2 Instance - here I am running a script from path /home/ec2-user/Tools/script.sh that is performing some tasks on other AWS respurces
    command_ec2 = ssm.send_command(InstanceIds=[Instance_ID], DocumentName='AWS-RunShellScript', Parameters={'commands': ['/home/ec2-user/Tools/script.sh']})
    
    # Fetching command id for the output
    command_id = command_ec2['Command']['CommandId']
    
    # Delaying to let command id fetching complete
    time.sleep(3)
    
    # Fetching command output
    output = ssm.get_command_invocation(CommandId=command_id, InstanceId=Instance_ID)
        
    return {
            'statusCode': 200,
            'body': output
        }
  
  
