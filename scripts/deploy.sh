#!/bin/bash

# REQUIREMENTS
# AWS CLI v2 - https://github.com/aws/aws-cli/tree/v2

# Extract the list of attendees from the attendees file.
attendeesFile=attendees.txt
attendees=$(cat $attendeesFile)

# Specify the 12-digit AWS account ID of the production account.
ProductionAccountId=

# Specify the region where you are deploying the master template.
PrimaryRegionId=

# Specify the secondary region you will use for the lab
SecondaryRegionId=

# Specify the name of the IAM role that will be given access to the key created for the lab
CmkPolicyRole=

# Iterator variable to avoid deploying more than 8 labs at a time (avoids AWS rate limits)
i=1

# Deploy the stack for each attendee. On each 8th attendee's deployment, the script will wait until their deployment is complete before proceeding to avoid exceeding AWS rate limits.
for attendee in $attendees
do
    if [ $i == 8 ]
    then
        echo "Deploying lab for $attendee..." >> logs.txt && stack=$(aws cloudformation create-stack --capabilities CAPABILITY_IAM --template-url https://veeam-aws-cloudformation.s3.amazonaws.com/veeam-aws-lab/vbaws-lab-backup-primary-master-flex2.1.template --stack-name $attendee-backup-primary --output text --query "StackId" --region $PrimaryRegionId --parameters ParameterKey=UserName,ParameterValue=$attendee ParameterKey=ProductionAccountId,ParameterValue=$ProductionAccountId ParameterKey=PrimaryRegionId,ParameterValue=$PrimaryRegionId ParameterKey=SecondaryRegionId,ParameterValue=$SecondaryRegionId ParameterKey=CmkPolicyRole,ParameterValue=$CmkPolicyRole) && echo "Attendee lab stack ID is $stack" >> logs.txt && echo "Deployed stack for $attendee. Waiting until stack deployment is complete before proceeding..." >> logs.txt && aws cloudformation wait stack-create-complete --stack-name $stack && i=1
    else
        echo "Deploying lab for $attendee..." >> logs.txt && stack=$(aws cloudformation create-stack --capabilities CAPABILITY_IAM --template-url https://veeam-aws-cloudformation.s3.amazonaws.com/veeam-aws-lab/vbaws-lab-backup-primary-master-flex2.1.template --stack-name $attendee-backup-primary --output text --query "StackId" --region $PrimaryRegionId --parameters ParameterKey=UserName,ParameterValue=$attendee ParameterKey=ProductionAccountId,ParameterValue=$ProductionAccountId ParameterKey=PrimaryRegionId,ParameterValue=$PrimaryRegionId ParameterKey=SecondaryRegionId,ParameterValue=$SecondaryRegionId ParameterKey=CmkPolicyRole,ParameterValue=$CmkPolicyRole) && echo "Attendee lab stack ID is $stack" >> logs.txt && echo "Deployed stack for $attendee. Sleeping 10 seconds before next deployment..." >> logs.txt && i=$((i + 1)) && sleep 10
    fi
done