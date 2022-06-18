#!/bin/bash

# REQUIREMENTS
# AWS CLI v2 - https://github.com/aws/aws-cli/tree/v2

# Extract the list of stacks from the stacks file.
stacksFile=stacks.txt
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
