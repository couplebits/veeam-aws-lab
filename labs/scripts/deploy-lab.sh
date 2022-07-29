#!/bin/bash

# REQUIREMENTS
# AWS CLI v2 - https://github.com/aws/aws-cli/tree/v2

# Declare the file where the list of attendees is located.
attendeesFile=

# Specify the name of the network stack that will be deployed for the lab.
NetworkStackName=

# Specify the 12-digit AWS account ID of the production account.
ProductionAccountId=

# Specify the region where you are deploying the main template.
RegionId=

# Specify the region where the flex resources will be deployed.
FlexRegionId=

# Specify the name of the IAM role in the organization that will be used for administrative access in the lab.
AdminRole=

# Specify the role ID (starting with AROA) of the IAM role in the backup account that will be used for administrative access in the lab.
AdminRoleId=

# Specify the user ID (starting with AIDA) of the IAM user in the backup account that will be used for administrative access in the lab.
AdminUserId=

# Deploy the stack for the core network. Wait for the core network stack to complete before deploying attendee labs.
echo "Deploying core network stack for lab..." >> logs.txt && \
netstack=$(aws cloudformation create-stack --capabilities CAPABILITY_NAMED_IAM \
--template-url https://veeam-aws-cloudformation.s3.amazonaws.com/veeam-aws-lab/v3/vbaws-lab-core-network-lab.template \
--stack-name $NetworkStackName --output text --query "StackId" --region $RegionId \
--parameters \
ParameterKey=VpcCidr,ParameterValue=10.0.0.0/16 \
ParameterKey=AdminRole,ParameterValue=$AdminRole) && \
echo "Core network stack ID is $netstack." >> logs.txt && \
echo "Waiting for core network deployment to complete before proceeding..." >> logs.txt && \
echo $netstack >> networkstack.txt && \
aws cloudformation wait stack-create-complete --stack-name $netstack && \
echo "Deployed core network stack. Deploying attendee labs..." >> logs.txt

# Extract the list of attendees from the attendees file.
attendees=$(cat $attendeesFile)

# Iterator variable to prevent deploying more than 8 labs at a time to avoid AWS rate limits.
i=1

# Iterator variable for VPC CIDR blocks.
vpc=1

# Deploy the stack for each attendee.
# On each 8th attendee's deployment, the script will wait until their deployment is complete before proceeding to avoid exceeding AWS rate limits.
for attendee in $attendees
do
    if [ $i == 8 ]
    then
        echo "Deploying lab for $attendee..." >> logs.txt && \
        stack=$(aws cloudformation create-stack --capabilities CAPABILITY_IAM \
        --template-url https://veeam-aws-cloudformation.s3.amazonaws.com/veeam-aws-lab/v3/vbaws-lab-backup-main-lab.template \
        --stack-name $attendee-backup-stack --output text --query "StackId" --region $RegionId \
        --parameters \
        ParameterKey=UserName,ParameterValue=$attendee \
        ParameterKey=ProductionAccountId,ParameterValue=$ProductionAccountId \
        ParameterKey=RegionId,ParameterValue=$RegionId \
        ParameterKey=FlexRegionId,ParameterValue=$FlexRegionId \
        ParameterKey=VpcCidr,ParameterValue=10.$vpc.0.0/16 \
        ParameterKey=AdminRole,ParameterValue=$AdminRole \
        ParameterKey=AdminRoleId,ParameterValue=$AdminRoleId \
        ParameterKey=AdminUserId,ParameterValue=$AdminUserId \
        ParameterKey=NetworkStackName,ParameterValue=$NetworkStackName) && \
        echo "Attendee lab stack ID is $stack" >> logs.txt && \
        echo $stack >> stacks.txt && \
        echo "Deployed stack for $attendee. Waiting until stack deployment is complete before proceeding..." >> logs.txt && \
        aws cloudformation wait stack-create-complete --stack-name $stack && \
        i=1 && vpc=$((vpc + 1))
    else
        echo "Deploying lab for $attendee..." >> logs.txt && \
        stack=$(aws cloudformation create-stack --capabilities CAPABILITY_IAM \
        --template-url https://veeam-aws-cloudformation.s3.amazonaws.com/veeam-aws-lab/v3/vbaws-lab-backup-main-lab.template \
        --stack-name $attendee-backup-stack --output text --query "StackId" --region $RegionId \
        --parameters \
        ParameterKey=UserName,ParameterValue=$attendee \
        ParameterKey=ProductionAccountId,ParameterValue=$ProductionAccountId \
        ParameterKey=RegionId,ParameterValue=$RegionId \
        ParameterKey=FlexRegionId,ParameterValue=$FlexRegionId \
        ParameterKey=VpcCidr,ParameterValue=10.$vpc.0.0/16 \
        ParameterKey=AdminRole,ParameterValue=$AdminRole \
        ParameterKey=AdminRoleId,ParameterValue=$AdminRoleId \
        ParameterKey=AdminUserId,ParameterValue=$AdminUserId \
        ParameterKey=NetworkStackName,ParameterValue=$NetworkStackName) && \
        echo "Attendee lab stack ID is $stack" >> logs.txt && \
        echo $stack >> stacks.txt && \
        echo "Deployed stack for $attendee. Sleeping 10 seconds before next deployment..." >> logs.txt && \
        i=$((i + 1)) && vpc=$((vpc + 1)) && \
        sleep 10
    fi
done
