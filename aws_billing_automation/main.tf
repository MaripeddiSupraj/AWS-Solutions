# ---------------------------------------------------
# Terraform Provider Configuration for AWS
# ---------------------------------------------------

# Specify the AWS provider and the desired region
provider "aws" {
  region = "us-east-1"  # Change to your preferred AWS region
}

# ---------------------------------------------------
# 1. Create an S3 Bucket to Store Billing Data
# ---------------------------------------------------

# Create an S3 bucket to store AWS billing data
resource "aws_s3_bucket" "billing_data_bucket" {
  bucket = "my-aws-billing-data-bucket-unique"  # Ensure this bucket name is unique globally
  acl    = "private"  # Bucket access is private

  tags = {
    Name        = "AWS Billing Data Bucket"
    Environment = "Production"
  }
}

# Enable versioning on the S3 bucket to retain multiple versions of objects
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.billing_data_bucket.id

  versioning_configuration {
    status = "Enabled"  # Enables versioning
  }
}

# Enable server-side encryption using AES256 for data protection
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.billing_data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # Use AES256 encryption
    }
  }
}

# Configure lifecycle rules to automatically delete objects older than 30 days
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.billing_data_bucket.id

  rule {
    id     = "DeleteOldBillingReports"  # Rule identifier
    status = "Enabled"  # Lifecycle rule is active

    expiration {
      days = 30  # Delete objects after 30 days
    }

    filter {
      prefix = "billing-report-"  # Apply rule to objects with this prefix
    }
  }
}

# ---------------------------------------------------
# 2. Create IAM Role for Lambda Execution
# ---------------------------------------------------

# Create an IAM role that allows Lambda functions to assume this role
resource "aws_iam_role" "lambda_role" {
  name = "LambdaCostExplorerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"  # Lambda can assume this role
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"  # Service principal for Lambda
        }
      },
    ]
  })
}

# ---------------------------------------------------
# 3. Attach IAM Policies to Lambda Role
# ---------------------------------------------------

# Create a policy that allows Lambda to access Cost Explorer, S3, and CloudWatch logs
resource "aws_iam_policy" "lambda_policy" {
  name        = "LambdaCostExplorerS3Policy"
  description = "Policy to allow Lambda to access Cost Explorer and S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage"  # Access AWS Cost Explorer API
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"  # Allow uploading objects to S3
        ]
        Resource = "${aws_s3_bucket.billing_data_bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",   # Allow log group creation
          "logs:CreateLogStream",  # Allow log stream creation
          "logs:PutLogEvents"      # Allow logging events
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach the IAM policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# ---------------------------------------------------
# 4. Create the Lambda Function
# ---------------------------------------------------

# Deploy the Lambda function to fetch billing data
resource "aws_lambda_function" "billing_fetcher" {
  filename         = "lambda_function_payload.zip"  # Path to the zipped Lambda function code
  function_name    = "BillingFetcherEvery5Minutes"  # Name of the Lambda function
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"  # Lambda handler entry point
  runtime          = "python3.10"  # Lambda runtime environment
  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  # Environment variables for Lambda
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.billing_data_bucket.bucket
    }
  }

  timeout     = 60  # Timeout in seconds (adjust as needed)
  memory_size = 128  # Memory allocation in MB
}

# ---------------------------------------------------
# 5. Create an EventBridge Rule to Schedule Lambda Execution
# ---------------------------------------------------

# Create a rule to trigger the Lambda function once a day
resource "aws_cloudwatch_event_rule" "daily_schedule" {
  name                = "BillingFetchDailyRule"
  description         = "Triggers the Lambda function once a day"
  schedule_expression = "rate(1 day)"  # Schedule Lambda execution every day
}

# ---------------------------------------------------
# 6. Add Lambda Function as the Target for EventBridge Rule
# ---------------------------------------------------

# Set the Lambda function as a target for the EventBridge rule
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_schedule.name
  target_id = "BillingFetcherLambda"
  arn       = aws_lambda_function.billing_fetcher.arn
}

# ---------------------------------------------------
# 7. Grant EventBridge Permission to Invoke the Lambda Function
# ---------------------------------------------------

# Allow EventBridge to invoke the Lambda function
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.billing_fetcher.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule.arn
}

# ---------------------------------------------------
# 8. Output the S3 Bucket Name
# ---------------------------------------------------

# Output the name of the S3 bucket created for billing data storage
output "s3_bucket_name" {
  description = "Name of the S3 bucket where billing data is stored"
  value       = aws_s3_bucket.billing_data_bucket.bucket
}