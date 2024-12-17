
AWS Billing Data Fetcher

This project automates the retrieval of AWS cost and usage data using AWS Cost Explorer and uploads it as JSON files to an S3 bucket. The project leverages Terraform for AWS resource provisioning and a Python Lambda function for cost data fetching.

Overview

The project includes:
	1.	Terraform Infrastructure:
	•	Creates an S3 bucket to store billing reports.
	•	Configures an IAM role and policies for Lambda.
	•	Deploys an AWS Lambda function.
	•	Schedules the Lambda function daily using EventBridge.
	2.	Python Lambda Function:
	•	Fetches the last 7 days of billing data from AWS Cost Explorer.
	•	Uploads the data in JSON format to the S3 bucket.

Project Structure

.
├── main.tf                       # Terraform configuration
├── lambda/
│   ├── lambda_function.py        # Python Lambda function code
│   └── lambda_function_payload.zip # Zipped Lambda function (generated)
└── README.md                     # Project documentation

Pre-requisites

Ensure the following tools are installed on your system:
	•	AWS CLI (configured with appropriate permissions)
	•	Terraform (version >= 1.0)
	•	Python 3.10 or later

Setup Instructions

1. Clone the Repository

git clone https://github.com/your-username/aws-billing-fetcher.git
cd aws-billing-fetcher

2. Prepare the Lambda Function

Navigate to the lambda/ directory and zip the Lambda function code:

cd lambda
zip -r lambda_function_payload.zip lambda_function.py
cd ..

	Note: Ensure lambda_function.py is in the correct path and zipped properly, as Terraform requires this file to deploy the Lambda function.

3. Deploy Terraform Infrastructure

Initialize and apply the Terraform configuration:

# Initialize Terraform
terraform init

# Preview the changes
terraform plan

# Deploy the infrastructure
terraform apply

	Confirm with yes when prompted. Terraform will provision:
		•	S3 Bucket
	•	IAM Role and Policies
	•	Lambda Function
	•	EventBridge Rule for scheduling

4. Verify Deployment
	•	S3 Bucket: Billing reports will be stored in the S3 bucket.
	•	Lambda Function: Verify the Lambda function is deployed via the AWS Lambda Console.
	•	EventBridge Rule: Check the rule BillingFetchDailyRule in the AWS EventBridge Console to confirm the schedule.

Testing Locally

You can test the Lambda function locally with the boto3 library and mock data.
	1.	Install dependencies:

pip install boto3


	2.	Run the script locally:

python lambda/lambda_function.py

Clean Up

To delete all resources created by Terraform:

terraform destroy

Confirm the destruction by typing yes. This will remove the Lambda function, S3 bucket, IAM roles, and EventBridge rules.

Troubleshooting
	•	Permission Issues: Verify your AWS CLI user/role has permissions for S3, Lambda, Cost Explorer, and CloudWatch.
	•	Duplicate Bucket Name: Update the bucket name in main.tf if there’s a naming conflict.
	•	Lambda Errors: Check CloudWatch Logs for execution errors.

Future Enhancements
	•	Add email notifications via SNS for cost reports.
	•	Support multi-region cost data retrieval.
	•	Extend granularity options beyond daily reports.

License

This project is licensed under the MIT License.

Contributing

Contributions are welcome! Open an issue or submit a pull request with improvements or suggestions.

Contact

For questions or feedback, contact the repository owner or open an issue.

Python Lambda Packaging Command

If you need to update the Lambda function, use the following command:

cd lambda
zip -r lambda_function_payload.zip lambda_function.py
cd ..
