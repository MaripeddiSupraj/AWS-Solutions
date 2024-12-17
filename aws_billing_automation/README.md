AWS Billing Data Fetcher
This project automates AWS cost and usage data retrieval using AWS Cost Explorer and stores the data as JSON files in an S3 bucket. The project provisions infrastructure with Terraform and uses an AWS Lambda function for cost data processing.

Table of Contents

1.    Overview
2.    Project Structure
3.    Pre-requisites
4.    Setup Instructions
5.    Testing Locally
6.    Clean Up
7.    Troubleshooting
8.    Future Enhancements
9.    License
10.    Contributing
11.    Contact
Overview

This project performs the following:
• Creates an S3 bucket for storing billing reports.
• Deploys an IAM role and necessary policies for Lambda.
• Schedules a Lambda function to fetch billing data from AWS Cost Explorer daily.
• Saves the data as a JSON file in the S3 bucket.

Project Structure

.
├── main.tf # Terraform configuration file
├── lambda/
│ ├── lambda_function.py # Python Lambda function code
│ └── lambda_function_payload.zip # Zipped Lambda function (created during setup)
└── README.md # Project documentation

Pre-requisites

Ensure you have the following tools installed:
• AWS CLI (configured with necessary permissions)
• Terraform (version >= 1.0)
• Python 3.10

Setup Instructions

Clone the Repository
git clone https://github.com/your-username/aws-billing-fetcher.git
cd aws-billing-fetcher

Package the Lambda Function
Navigate to the lambda/ folder and zip the function:

cd lambda
zip -r lambda_function_payload.zip lambda_function.py
cd ..

Deploy Terraform Infrastructure
Use Terraform to set up the required AWS resources:

Initialize Terraform
terraform init

Preview the resources to be created
terraform plan

Apply the Terraform configuration
terraform apply

When prompted, type yes to confirm.

Verify Deployment
S3 Bucket: Confirm that the S3 bucket is created and ready to receive billing reports.
Lambda Function: Verify that the Lambda function appears in the AWS Lambda Console.
EventBridge Rule: Check for the daily schedule in the AWS EventBridge Console under rules.
Testing Locally

To test the Lambda function locally:

1.    Install the required Python library:
pip install boto3

2.    Run the Lambda function script locally:
python lambda/lambda_function.py

Clean Up

To destroy all the resources created by Terraform, run:

terraform destroy

Confirm by typing yes when prompted.

Troubleshooting
• Permissions Error: Ensure your AWS CLI user/role has permissions for S3, Lambda, Cost Explorer, and CloudWatch.
• Duplicate S3 Bucket Name: Update the bucket name in main.tf to something globally unique.
• Lambda Execution Errors: Check the Lambda function logs in AWS CloudWatch Logs.

Future Enhancements
• Add email notifications for cost report delivery using SNS.
• Add multi-region cost aggregation.
• Include hourly cost granularity for detailed analysis.

License

This project is licensed under the MIT License. See the LICENSE file for details.

Contributing

Contributions are welcome! To contribute:

1.    Fork the repository.
2.    Create a new branch: git checkout -b feature/your-feature-name.
3.    Commit your changes: git commit -m "Add your feature description".
4.    Push to the branch: git push origin feature/your-feature-name.
5.    Submit a pull request.
Contact

For any issues, questions, or suggestions, feel free to open an issue on this repository.

Lambda Function Packaging Command

If you modify the lambda_function.py file, repackage it using:

cd lambda
zip -r lambda_function_payload.zip lambda_function.py
cd ..