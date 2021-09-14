#!/bin/bash

# REQUIREMENTS
# AWS CLI v2 - https://github.com/aws/aws-cli/tree/v2

# Extract the list of attendees from the attendees file.
attendeesFile=attendees.txt
attendees=$(cat $attendeesFile)

# Iterator variable to avoid deleting more than 8 labs at a time (avoids AWS rate limits)
i=1

# Delete the stack for each attendee.
for attendee in $attendees
do
    if [ $i == 8 ]
    then
        echo "Deleting lab for $attendee..." >> logs.txt && stack=$(aws cloudformation describe-stacks --stack-name $attendee-backup-primary --query 'Stacks[0].StackId' --output text) && echo "Attendee lab stack ID is $stack" >> logs.txt && aws cloudformation delete-stack --stack-name $stack && echo "Deletion command for $attendee successful. Waiting for deletion to complete before proceeding..." >> logs.txt && aws cloudformation wait stack-delete-complete --stack-name $stack && i=1
    else
        echo "Deleting lab for $attendee..." >> logs.txt && stack=$(aws cloudformation describe-stacks --stack-name $attendee-backup-primary --query 'Stacks[0].StackId' --output text) && echo "Attendee lab stack ID is $stack" >> logs.txt && aws cloudformation delete-stack --stack-name $stack && echo "Deletion command for $attendee successful. Sleeping 10 seconds before next deletion..." >> logs.txt && i=$((i + 1)) && sleep 10
    fi
done
