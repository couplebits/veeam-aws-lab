# Veeam Backup for AWS Lab
Cloudformation templates for deploying Veeam Backup for AWS lab into two accounts and regions and bash scripts for mass deployments and clean-up.

Created by Eric Ellenberg - Public Cloud Solutions, Veeam

## REQUIREMENTS
The lab is deployed using a CloudFormation template that will deploy lab resources into two regions within two AWS accounts. **The deployment will fail if you have not fulfilled the requirements.**

* (2) AWS Accounts
  - One account to serve as the backup account. This account is where Veeam Backup for AWS instance and associated resources will be deployed.
  - One account to serve as the production account. This account is where the EC2 instances to be protected will be deployed.
  - Lab users must be given administrative access to both AWS accounts to perform various AWS configuration changes and tasks.

* Within the backup account:
  - An active subscription to the Veeam Backup for AWS Free Edition from the AWS Marketplace.
  - The CloudFormation StackSet Administration role (template provided by AWS): https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetAdministrationRole.yml
  - The CloudFormation StackSet Execution role (template provided by AWS): https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetExecutionRole.yml
  - (1) EC2 key pair in the primary region, named exactly as follows: _vbaws-lab-backup-primary_

* Within the production account: 
  - The CloudFormation StackSet Execution role (template provided by AWS): https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetExecutionRole.yml
  - (1) EC2 key pair in the primary region, named exactly as follows: _vbaws-lab-prod-primary_
  - (1) EC2 key pair in the secondary region, named exactly as follows: _vbaws-lab-prod-secondary_
  - (1) IAM role that allows users to manage the CMKs that will be created in the secondary region and used to encrypt the EBS volume attached to their instance. 

### IMPORTANT
The StackSet Execution role is deployed with the AWS-managed Administrator IAM policy attached, giving the role full administrative access to all actions and resources within the account. To prevent unauthorized administrative access, edit the trust relationship on the CloudFormation StackSet Execution role in both AWS accounts to allow only the Administration role in the backup account to assume it. 
 
The trust policy on the StackSet Execution role should appear similar to the following example. The 12-digit AWS account ID in the following example, 123456789012, should be replaced with the account ID of the backup account where the Administration role is deployed.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/AWSCloudFormationStackSetAdministrationRole"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

For more details on CloudFormation StackSet roles and self-managed permissions, visit: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacksets-prereqs-self-managed.html

## DEPLOYMENT - HOW TO DEPLOY THE LAB
1) Login to the AWS account which will serve as the backup account.
2) From the top right corner of the AWS management console, select the region which will be used as the primary region for the lab from the dropdown.
3) Using the Services menu top-left or the search field top-center, select CloudFormation.
4) On the left column, select Stacks.
5) In the upper right corner, select the "Create stack" dropdown, then choose "With new resources (standard)".
6) In the Amazon S3 URL field, paste the following template URL: https://veeam-aws-cloudformation.s3.amazonaws.com/veeam-aws-lab/vbaws-lab-backup-primary-master.template
7) Click Next.
8) For the Stack name, enter the user's name code (5 characters maximum), followed by "-backup-primary". Example: _veeam-backup-primary_
9) In the Username field, enter the user's name code (5 characters maximum). Example: _veeam_
10) In the Production Account field, enter the 12-digit AWS account ID of the account which will serve as the production account.
11) In the Regions fields, enter the region IDs of the two regions which will be used for the lab. The primary region ID should match your current region ID where you are deploying the template.
12) In the CMK Policy Role field, enter the name of the IAM role in the production account that will be given access to the CMK created for the lab.
13) Click Next.
14) Everything on the Configure stack options page can be left at the default values. Click Next.
15) Scroll to the bottom of the page and tick the checkbox to acknowledge creation of IAM resources.
16) Select Create stack.

The user's lab resources will be deployed into both AWS accounts and both regions within the two accounts. This usually takes 4-5 minutes.

## DEPLOYMENT - LIST OF RESOURCES
The following resources will be created for each lab attendee:

* Backup account
  - Global
    - (3) IAM roles required by Veeam Backup for AWS
    - (3) IAM roles for Lambda functions used for removing resources upon lab conclusion
  - Primary region
    - (1) VPC and associated resources
    - (1) EC2 instance of Veeam Backup for AWS
    - (1) S3 bucket
    - (1) Lambda function to empty the S3 bucket prior to deletion when the stack is deleted upon lab conclusion
  - Secondary region
    - (1) VPC and associated resources
    - (4) VPC interface endpoints: ebs, ec2messages, sqs, ssm
    - (1) S3 bucket
    - (2) Lambda functions: 
      - (1) to empty the S3 bucket prior to deletion when the stack is deleted upon lab conclusion
      - (1) to remove S3 endpoints in each individual's VPC prior to VPC deletion when the stack is deleted upon lab conclusion

* Production account
  - Primary region
    - (1) VPC and associated resources
    - (1) EC2 instance running Windows Server 2019 base
  - Secondary region
    - (1) VPC and associated resources
    - (1) EC2 instance running Ubuntu 20.04
    - (1) Customer managed key (CMK) to encrypt the EBS volume attached to the Ubuntu instance

## TEARDOWN - PART 1/2 - HOW TO DELETE THE LAB
1) Log into the AWS account being used as the backup account. 
2) From the top right corner of the AWS management console, select the region that was used as the primary region for the lab from the dropdown.
3) Using the Services menu top-left or the search field top-center, select CloudFormation.
4) On the left column, select Stacks.
5) Select the user's stack, then click the Delete button.
5) Click the orange Delete button which appears in the pop-up window.

The user's resources which were deployed by CloudFormation in both accounts and both regions will be deleted. Please be patient as this can take some time.

## TEARDOWN - PART 2/2 - MANUAL STEPS
During the lab, attendees will create IAM roles and policies. Other resources such as EBS snapshots are created by Veeam Backup for AWS during the lab. These resources must be removed manually. 
 
### IMPORTANT 
**DO NOT** remove these resources before you have deleted lab users' CloudFormation stacks. CloudFormation stacks for all lab users must be in the DELETE_COMPLETE state prior to removing the following resources.

The following resources must be manually removed after all CloudFormation stacks have been deleted:
* Backup account
  - Global 
    - CloudFormation Administration and Execution roles
    - (Optional) IAM user with programmatic access - if you performed mass deployments using the AWS CLI
  - Primary region 
    - EBS volumes (20 GB) which were attached to Veeam Backup for AWS instances
    - Snapshots of VBAWS instances created by data lifecycle manager policies
    - The EC2 key pair named "vbaws-lab-backup-primary"
    - Lambda function log groups in CloudWatch
  - Secondary region
    - Lambda function log groups in CloudWatch
  - Extra credit / prize region 
    - VPCs which are restored to the region used for the extra credit / prize portion of the lab to simulate restores of VPCs using VBAWS

* Production account
  - Global 
    - IAM roles named "source" that are created by attendees to simulate creation of a cross-account IAM role to be used by VBAWS
    - IAM roles named "instance" that are created by attendees to simulate creation of instance profile roles to configure SSM and application-consistent snapshots
    - IAM policies named "source", "vss", and "vpc" that are applied to the source and instance roles
    - CloudFormation StackSet Execution role
  - Primary region
    - Snapshots of the EBS volumes which were connected to the Windows instances
    - The EC2 key pair named _vbaws-lab-prod-primary_
  - Secondary region
    - Snapshots of the EBS volumes which were connected to the Ubuntu instances 
    - The EC2 key pair named _vbaws-lab-prod-secondary_

## MASS DEPLOYMENT
If you are deploying this lab for a large group of users, I have written scripts to accomplish the deployment and teardown processes quickly and simply. They are found in the scripts directory in this repo.

### REQUIREMENTS - MASS DEPLOYMENT
- An IAM user with programmatic access enabled.
  - You will need an access and secret key to configure the AWS CLI to access the AWS account that will serve as your backup account.
- Access to a bash shell on Linux (can be a VM or WSL distro - this script was tested with Ubuntu 20.04)
- Install the AWS CLI v2 - https://github.com/aws/aws-cli/tree/v2
- A text file named _attendees.txt_ with a list of all lab attendee names formatted in 5 characters or less.
  - Only lowercase letters and the numbers 0-9 are allowed.
  - **If you create the file in Windows:** The deploy script expects standard UNIX line breaks (LF). Ensure that your text editor of choice saves the text file with LF line breaks. VS Code can do this easily.

### MASS DEPLOYMENT - HOW TO DEPLOY
1) Open the _deploy.sh_ script in your text editor.
2) Enter the values for the following deployment parameters next to the = sign:
   - ProductionAccountId
   - PrimaryRegionId - **the primary region ID must match the region ID where you are deploying the master template**
   - SecondaryRegionId
   - CmkPolicyRole
3) Place the _attendees.txt_ file and the _deploy.sh_ script in the same directory in the Linux box.
4) Use the _cd_ command to go to the directory where you placed these files.
5) At the command line, enter:
```
bash ./deploy.sh
```
The script will iterate through the list of attendees and deploy their resources into the accounts and regions specified, 8 users at a time. This limit has been implemented to avoid exceeding AWS rate limits and causing errors.

## MASS TEARDOWN - HOW TO DELETE
1) In the scripts directory, find the _teardown.sh_ script.
2) Place the _teardown.sh_ script in the same directory as the _attendees.txt_ file.
3) Use the _cd_ command to go to the directory where you placed the script.
3) At the command line, enter:
```
bash ./teardown.sh
```

The script will iterate through the list of attendees and delete their resources, 8 users at a time. This limit has been implemented to avoid exceeding AWS rate limits and causing errors.

### NOTES ON MASS DEPLOYMENT
- Be mindful of AWS service quotas. In particular, the default VPC quota is limited to (5) VPCs per region. Quotas must be increased in both regions within both accounts, four regions total.
- In the backup account primary region, the AWS service quota for _Stack sets per administrator account_ may need to be increased, as each user's deployment includes 3 stack sets.
