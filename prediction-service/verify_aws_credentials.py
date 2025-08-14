import os
import boto3
from dotenv import load_dotenv

def verify_credentials():
    """Simple script to verify AWS credentials"""
    try:
        # Load environment variables
        load_dotenv()
        
        # Print AWS region being used
        region = os.getenv('AWS_REGION')
        print(f"Using AWS Region: {region}")
        
        # Try to create a DynamoDB client
        dynamodb = boto3.client(
            'dynamodb',
            aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
            aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
            region_name=region
        )
        
        # Try to list tables (this is a simple operation that requires minimal permissions)
        response = dynamodb.list_tables()
        print("\nSuccessfully connected to AWS!")
        print("Available DynamoDB tables:")
        for table in response['TableNames']:
            print(f"- {table}")
            
    except Exception as e:
        print(f"\nError: {str(e)}")
        print("\nDebugging information:")
        print("1. Check if your credentials are correctly formatted in .env file")
        print("2. Make sure there are no extra spaces or quotes in the credentials")
        print("3. Verify that your IAM user has DynamoDB permissions")

if __name__ == "__main__":
    print("Verifying AWS Credentials...")
    verify_credentials()
