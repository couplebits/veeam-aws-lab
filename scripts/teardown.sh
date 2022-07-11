#!/bin/bash

# REQUIREMENTS
# AWS CLI v2 - https://github.com/aws/aws-cli/tree/v2

# Declare the files where the stack IDs are located for the network stack and attendee lab stacks.
# The defaults reflect the deploy script's unmodified configuration.
stacksFile=stacks.txt
networkStackFile=networkstack.txt

# Extract the list of stacks from the stacks file.
stacks=$(cat $stacksFile)

# Iterator variable to prevent deleting more than 8 stacks at a time to avoid AWS rate limits.
i=1

# Delete the stacks.
for stack in $stacks
do
    if [ $i == 8 ]
    then
        echo "Deleting $stack..." >> logs.txt && \
        aws cloudformation delete-stack --stack-name $stack && \
        echo "Deletion command for $stack successful. Waiting for deletion to complete before proceeding..." >> logs.txt && \
        aws cloudformation wait stack-delete-complete --stack-name $stack && \
        i=1
    else
        echo "Deleting $stack..." >> logs.txt && \
        aws cloudformation delete-stack --stack-name $stack && \
        echo "Deletion command for $stack successful. Sleeping 10 seconds before next deletion..." >> logs.txt && \
        i=$((i + 1)) && \
        sleep 10
    fi
done

# Prompt to confirm that all attendee stacks are deleted before attempting delete of the core network stack.
read -n 1 -r -s -p "Confirm that all attendee stacks are in DELETE_COMPLETE status, then press enter to continue..."

# Extract the stack ID from the network stack file.
networkStack=$(cat networkstack.txt)

# Delete the core network stack, then wait until it is done.
aws cloudformation delete-stack --stack-name $networkStack
echo "Deletion command for $networkStack successful." >> logs.txt
aws cloudformation wait stack-delete-complete --stack-name $networkStack
echo "Deletion of the core network stack is complete." >> logs.txt
echo "Thank you for using this lab." >> logs.txt

# (OPTIONAL) Remove the stacks file and networkstack file after the teardown is complete.
# rm $stacksFile $networkStackFile
