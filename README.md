# Veeam Backup for AWS Lab, Third Edition

## Information

Created by Eric Ellenberg, Veeam Software

The flex3 branch on this repo is for Veeam's AWS Flex Lab, Third Edition.

## Objectives

This lab simulates an environment where VBAWS is deployed into a private subnet that routes internet traffic through a transit gateway and core VPC. Each lab attendee has their own VPC with a public subnet that contains a Windows jumpbox for them to access the VBAWS appliance deployed in the private subnet.

## Requirements

The lab is deployed using two CloudFormation templates that will deploy lab resources into two AWS accounts. **The deployment will fail if you have not fulfilled the requirements.**

* (2) AWS Accounts
  * One account to serve as the backup account. This account is where the Veeam Backup for AWS EC2 instance and associated resources will be deployed.
  * One account to serve as the production account. This account is where the EC2 instance to be protected will be deployed.
  * Lab users must be given administrative access to both AWS accounts to perform various AWS configuration changes and tasks.

* Within the backup account:
  * An active subscription to the Veeam Backup for AWS Free Edition from the AWS Marketplace.
  * The CloudFormation StackSet Administration role (template provided by AWS): <https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetAdministrationRole.yml>
  * The CloudFormation StackSet Execution role (template provided by AWS): <https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetExecutionRole.yml>
  * (1) EC2 key pair, named exactly as follows: _vbaws-lab-backup_
  * (1) IAM role (called _AdminRole_ in the template) that allows users to manage S3 bucket policies in the backup account.

* Within the production account:
  * The CloudFormation StackSet Execution role (template provided by AWS): <https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetExecutionRole.yml>
  * (1) EC2 key pair, named exactly as follows: _vbaws-lab-prod_
  * (1) IAM role (called _AdminRole_ in the template) that allows users to manage KMS keys used for EBS encryption in the production account.

### CloudFormation Role Security

The StackSet Execution role is deployed with the AWS-managed _AdministratorAccess_ IAM policy attached, giving the role full access to all actions and resources within the account. To prevent unauthorized administrative access, edit the trust relationship on the Execution role in both AWS accounts to allow only the Administration role in the backup account to assume it.

The trust policy on the Execution role should appear similar to the following example. The 12-digit AWS account ID in the following example, 123456789012, should be replaced with the account ID of the backup account where the Administration role is deployed.

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

For more details on CloudFormation StackSet roles and self-managed permissions, visit: <https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacksets-prereqs-self-managed.html>

## Deployment

### Deploy core network stack

1. Login to the AWS account which will serve as the backup account.
2. From the top right corner of the AWS management console, select the region where lab resources will be deployed.
3. Using the Services menu top-left or the search field top-center, select CloudFormation.
4. On the left column, select Stacks.
5. In the upper right corner, select the "Create stack" dropdown, then choose "With new resources (standard)".
6. In the Amazon S3 URL field, paste the following template URL: <https://veeam-aws-cloudformation.s3.amazonaws.com/veeam-aws-lab/v3/vbaws-lab-core-network.template>
7. Click Next.
8. For the Stack name, enter a name for the core network stack. Example: _core-network-stack_
9. Enter the CIDR block that will be used for the core VPC, e.g., "10.0.0.0/16".
10. Click Next.
11. Everything on the Configure stack options page can be left at the default values. Click Next.
12. Scroll to the bottom of the page and select Create stack.

### Deploy lab attendee stack

1. In the CloudFormation Stacks view, select the "Create stack" dropdown, then choose "With new resources (standard)".

2. In the Amazon S3 URL field, paste the following template URL: <https://veeam-aws-cloudformation.s3.amazonaws.com/veeam-aws-lab/v3/vbaws-lab-backup-main.template>

3. For the Stack name, enter the user's name code (5 characters maximum), followed by "-backup-stack". Example: _veeam-backup-stack_

4. In the Username field, enter the user's name code (5 characters maximum). Example: _veeam_

5. In the Production Account field, enter the 12-digit AWS account ID of the account which will serve as the production account.

6. In the Region field, enter the region ID of the region where lab resources will be deployed. The region ID should match your current region ID where you deployed the core network stack and are deploying this stack.

7. In the VPC CIDR field, enter the CIDR block that will be used for the attendee's VPC, e.g., 10.10.0.0/16. **NOTE:** The CIDR block of the lab attendee's VPC should not overlap with each other nor the core network VPC.
8. In the _Core Network Stack_ field, enter the name of the core network stack from step 8 in the core network stack deployment. **NOTE:** The lab attendee stack imports values from the core network stack to hook up the network components.
9. In the Admin Role field, enter the name of the IAM role (just the name, not the ARN) in the production account that will be given access to the KMS key created for the lab.
10. In the Admin Role ID field, enter the role ID of the IAM role in the backup account that will be given access to the bucket created for the lab (use the AWS CLI to find this value)
11. In the Admin User ID field, enter the user ID of the user in the backup account that will be given access to the bucket created for the lab (use the AWS CLI to find this value)
12. Do not edit the Windows AMI field. The lab will deploy that latest available AMI of Windows Server 2022 so that the Edge browser is available out of the box.
13. Click Next.
14. Everything on the Configure stack options page can be left at the default values. Click Next.
15. Scroll to the bottom of the page and tick the checkbox to acknowledge creation of IAM resources.
16. Select Create stack.

The user's lab resources will be deployed into both AWS accounts. This usually takes 4-5 minutes.

## Resources

* Backup account
  * Global
    * (3) IAM roles for Veeam Backup for AWS and a Lambda function used for removing resources upon lab conclusion
  * Lab Region
    * (1) Core Network VPC
    * (1) Transit Gateway attached to the Core VPC
    * (1) NAT Gateway in the Core VPC
    * (1) Elastic IP for the NAT gateway in the Core VPC
    * (1) VPC with a public subnet and private subnet
    * (2) EC2 instances: (1) Windows Server 2022 instance in the public subnet, (1) Veeam Backup for AWS instance in the private subnet
    * (1) S3 bucket
    * (1) Lambda function to empty the S3 bucket prior to deletion when the stack is deleted upon lab conclusion

* Production account
  * Global
    * (1) IAM role for Veeam Backup for AWS to perform backups and restores for EC2
  * Lab region
    * (1) VPC and associated resources
    * (1) EC2 instance running Ubuntu 22.04
    * (1) KMS key to encrypt the EBS volume attached to the Ubuntu instance

## Teardown - Part 1 of 2 - Stacks

1. Log into the AWS account being used as the backup account.
2. From the top right corner of the AWS management console, select the region that was used for the lab from the dropdown.
3. Using the Services menu top-left or the search field top-center, select CloudFormation.
4. On the left column, select Stacks.
5. Select the user's stack, then click the Delete button.
6. Click the orange Delete button which appears in the pop-up window.
7. When the all user stacks have been deleted and are in the **DELETE_COMPLETE** state, select the core network stack, then click the Delete button.
8. Click the orange Delete button which appears in the pop-up window.

The user's resources which were deployed by CloudFormation in both accounts will be deleted, followed by the core network resources.

Please be patient as this can take some time.

## Teardown - Part 2 of 2 - Manual steps

The templates in this repo perform all necessary network configuration. Deleting these stacks will remove all resources except for those which are created by the user performing backup policies, such as EBS snapshots. These resources must be removed manually.

**DO NOT** remove these resources before you have deleted the CloudFormation stacks for the lab. CloudFormation stacks must be in the **DELETE_COMPLETE** state prior to removing the following resources

The following resources must be manually removed _after all CloudFormation stacks have been deleted_:

* Backup account
  * CloudFormation Administration and Execution roles
  * (Optional) IAM user with programmatic access - if you performed mass deployments using the AWS CLI
  * The EC2 key pair named _vbaws-lab-backup_
  * Lambda function log groups in CloudWatch

* Production account
  * CloudFormation StackSet Execution role
  * Snapshots of the EBS volumes which were connected to the production instances that may have been created by backup policies
  * The EC2 key pair named _vbaws-lab-prod_

## Deployment for groups

If you are deploying this lab for a large group of users, I have written scripts to accomplish the deployment and teardown processes with minimal effort. They are found in the scripts directory in this repo.

### Notes on group deployments

* Be mindful of AWS service quotas. In particular, the default VPC quota is limited to (5) VPCs per region. Quotas must be increased within both accounts.
* In the backup account, the AWS service quota for _Stack sets per administrator account_ may need to be increased, as each user's deployment includes 1 stack set.

## Requirements for group deployments

* An IAM user with programmatic access enabled.
  * You will need an access and secret key to configure the AWS CLI to access the AWS account that will serve as your backup account.
* Bash - scripts were tested using Bash on macOS 12 and Ubuntu 20.04 & 22.04
* AWS CLI v2 - <https://github.com/aws/aws-cli/tree/v2>
* A text file named _attendees.txt_ with a list of all lab attendee names formatted in 5 characters or less.
  * Only lowercase letters and the numbers 0-9 are allowed.
  * **If you create the attendees file in Windows:** The deploy script expects standard UNIX line breaks (LF). Ensure that your text editor of choice saves the text file with LF line breaks.

## Using scripts for group deployments

1. In the scripts directory, open the _deploy.sh_ script in your text editor.
2. Enter the values for the following deployment parameters:
   * attendeesFile - the file containing the list of lab attendees, with usernames formatted with 5 characters or less
   * NetworkStackName - the name of the core network stack
   * ProductionAccountId - the 12-digit AWS account number of the production account
   * RegionId - **the region ID must match the region ID where you are deploying the backup-main template**
   * AdminRole - the name of the admin IAM role
   * AdminRoleID - the role ID of the admin role
   * AdminUserId - the user ID of an admin user
3. Place the _attendees.txt_ file and the _deploy.sh_ script in the same directory.
4. At the command line, enter:

```shell
bash ./deploy.sh
```

The script will first create the core network stack then iterate through the list of attendees and deploy their resources, 8 users at a time. This limit has been implemented to avoid exceeding AWS rate limits and causing errors.

## Using scripts for group deployment teardown

1. In the scripts directory, find the _teardown.sh_ script.
2. Place the _teardown.sh_ script in the same directory where the deploy script was executed. The deploy script creates log files that contain the stack IDs for the attendee stacks and the core network stack and uses these values to delete the stacks in order.
3. At the command line, enter:

```shell
bash ./teardown.sh
```

The script will iterate through the list of attendees and delete their resources, 8 users at a time. This limit has been implemented to avoid exceeding AWS rate limits and causing errors.
4. After all attendee stacks have been removed and are in the **DELETE_COMPLETE** state, press enter at the prompt in your terminal to proceed with the removal of the core network stack.
5. Manual removal of some resources is still required. Review the section named "Teardown - Part 2 of 2 - Manual steps" for details.
