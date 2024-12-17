import json
import boto3
from datetime import datetime, timedelta
import os

# Lambda function to fetch AWS cost and usage data and upload it to an S3 bucket
def lambda_handler(event, context):
    """
    AWS Lambda handler function that:
    1. Queries AWS Cost Explorer for cost and usage data (last 7 days, grouped by service).
    2. Processes the data into a JSON structure.
    3. Uploads the resulting JSON file to an S3 bucket.

    Args:
        event: AWS Lambda event input (not used in this function).
        context: AWS Lambda context object (not used in this function).

    Returns:
        dict: Status code, message, file name, and record count.
    """
    # Initialize AWS clients for Cost Explorer and S3
    ce = boto3.client('ce')  # AWS Cost Explorer client
    s3 = boto3.client('s3')  # AWS S3 client

    # Retrieve environment variables (bucket name)
    BUCKET_NAME = os.environ['BUCKET_NAME']  # S3 bucket where the report will be stored

    # Define the time period: Last 7 days (end date is today)
    end_date = datetime.utcnow().date()  # Current UTC date
    start_date = end_date - timedelta(days=7)  # Start date: 7 days ago

    try:
        # Query Cost Explorer API to get cost and usage data for all services
        response = ce.get_cost_and_usage(
            TimePeriod={
                'Start': start_date.strftime("%Y-%m-%d"),  # Format as 'YYYY-MM-DD'
                'End': end_date.strftime("%Y-%m-%d")
            },
            Granularity='DAILY',  # Daily granularity for cost data
            Metrics=["UnblendedCost"],  # Fetch unblended cost
            GroupBy=[{"Type": "DIMENSION", "Key": "SERVICE"}]  # Group data by service
        )
    except Exception as e:
        # Handle and log errors during the Cost Explorer API call
        print(f"Error fetching cost data: {e}")
        raise e

    # Process the response to extract relevant data
    results = []  # List to store processed cost data
    for time_period in response.get('ResultsByTime', []):
        date = time_period['TimePeriod']['Start']  # Get the date for this record
        for group in time_period.get('Groups', []):
            service_name = group['Keys'][0]  # AWS service name
            cost = group['Metrics']['UnblendedCost']['Amount']  # Cost amount
            unit = group['Metrics']['UnblendedCost']['Unit']  # Cost unit (e.g., USD)

            # Append data in a structured format
            results.append({
                "date": date,
                "service": service_name,
                "cost_amount": cost,
                "cost_unit": unit
            })

    # Convert the results into JSON format
    data_json = json.dumps(results, indent=2)

    # Generate a filename for the S3 upload (ISO timestamp format)
    timestamp = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")  # e.g., 2024-06-07T12:00:00Z
    filename = f"billing-report-{timestamp}.json"  # Unique file name based on timestamp

    try:
        # Upload the JSON data to the specified S3 bucket
        s3.put_object(
            Bucket=BUCKET_NAME,  # S3 bucket name
            Key=filename,  # File name in the bucket
            Body=data_json,  # Data to upload
            ContentType='application/json'  # Set content type to JSON
        )
    except Exception as e:
        # Handle and log errors during the S3 upload
        print(f"Error uploading to S3: {e}")
        raise e

    # Return success response with relevant information
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Billing data fetched and stored successfully.",
            "file": filename,
            "record_count": len(results)  # Total number of records processed
        })
    }