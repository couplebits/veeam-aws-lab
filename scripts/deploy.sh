#!/bin/bash

# REQUIREMENTS
# AWS CLI v2 - https://github.com/aws/aws-cli/tree/v2

# Extract the list of attendees from the attendees file.
attendeesFile=attendees.txt
attendees=$(cat $attendeesFile)

# Specify the name of the network stack that will be deployed for the lab.
NetworkStackName=

# Specify the 12-digit AWS account ID of the production account.
ProductionAccountId=

# Specify the region where you are deploying the master template.
RegionId=

# Specify the name of the IAM role that will be given access to the key created for the lab.
CmkPolicyRole=

# Deploy the stack for the core network. Wait for the core network stack to complete before deploying attendee labs.
echo "Deploying lab network stack..." >> logs.txt && \
netstack=$(aws cloudformation create-stack --capabilities CAPABILITY_IAM \
--template-url https://veeam-aws-cloudformation.s3.amazonaws.com/veeam-aws-lab/v3/vbaws-lab-core-network.template \
--stack-name $NetworkStackName --output text --query "StackId" --region $RegionId \
--parameters ParameterKey=VpcCidr,ParameterValue=10.0.0.0/16) && \
echo "Core network stack ID is $netstack." >> logs.txt && \
echo "Waiting for core network deployment to complete before proceeding..." >> logs.txt && \
echo $netstack >> networkstack.txt && \
aws cloudformation wait stack-create-complete --stack-name $netstack && \
echo "Deployed core network stack. Deploying attendee labs..." >> logs.txt

# Iterator variable to prevent deploying more than 8 labs at a time to avoid AWS rate limits.
i=1

# Iterator variable for VPC CIDR blocks.
vpc=1

# Deploy the stack for each attendee. On each 8th attendee's deployment, the script will wait until their deployment is complete before proceeding to avoid exceeding AWS rate limits.
for attendee in $attendees
do
    if [ $i == 8 ]
    then
        echo "Deploying lab for $attendee..." >> logs.txt && \
        stack=$(aws cloudformation create-stack --capabilities CAPABILITY_IAM \
        --template-url https://veeam-aws-cloudformation.s3.amazonaws.com/veeam-aws-lab/v3/vbaws-lab-backup-main.template \
        --stack-name $attendee-backup-stack --output text --query "StackId" --region $RegionId \
        --parameters ParameterKey=UserName,ParameterValue=$attendee ParameterKey=ProductionAccountId,ParameterValue=$ProductionAccountId \
        ParameterKey=RegionId,ParameterValue=$RegionId ParameterKey=VpcCidr,ParameterValue=10.$vpc.0.0/16 \
        ParameterKey=CmkPolicyRole,ParameterValue=$CmkPolicyRole ParameterKey=NetworkStackName,ParameterValue=$NetworkStackName) && \
        echo "Attendee lab stack ID is $stack" >> logs.txt && \
        echo $stack >> stacks.txt && \
        echo "Deployed stack for $attendee. Waiting until stack deployment is complete before proceeding..." >> logs.txt && \
        aws cloudformation wait stack-create-complete --stack-name $stack && \
        i=1 && vpc=$((vpc + 1))
    else
        echo "Deploying lab for $attendee..." >> logs.txt && \
        stack=$(aws cloudformation create-stack --capabilities CAPABILITY_IAM \
        --template-url https://veeam-aws-cloudformation.s3.amazonaws.com/veeam-aws-lab/v3/vbaws-lab-backup-main.template \
        --stack-name $attendee-backup-stack --output text --query "StackId" --region $RegionId \
        --parameters ParameterKey=UserName,ParameterValue=$attendee ParameterKey=ProductionAccountId,ParameterValue=$ProductionAccountId \
        ParameterKey=RegionId,ParameterValue=$RegionId ParameterKey=VpcCidr,ParameterValue=10.$vpc.0.0/16 \
        ParameterKey=CmkPolicyRole,ParameterValue=$CmkPolicyRole ParameterKey=NetworkStackName,ParameterValue=$NetworkStackName) && \
        echo "Attendee lab stack ID is $stack" >> logs.txt && \
        echo $stack >> stacks.txt && \
        echo "Deployed stack for $attendee. Sleeping 10 seconds before next deployment..." >> logs.txt && \
        i=$((i + 1)) && vpc=$((vpc + 1)) && \
        sleep 10
    fi
done