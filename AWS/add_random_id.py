import boto3
import random
import time
import sys
from decimal import Decimal

# --- Configuration ---
DYNAMODB_TABLE_NAME = 'WordleWords'
AWS_REGION = 'us-east-1' 

# --- Initialize DynamoDB client ---
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
table = dynamodb.Table(DYNAMODB_TABLE_NAME)

print(f"Attempting to add 'random_id' and '_PK' to items in table: {DYNAMODB_TABLE_NAME} in region {AWS_REGION}")

def add_random_id_to_items():
    total_updated = 0
    total_scanned = 0
    last_evaluated_key = None

    print("Scanning table to add random_id and _PK to each item...")
    while True:
        scan_args = {}
        if last_evaluated_key:
            scan_args['ExclusiveStartKey'] = last_evaluated_key

        try:
            # Corrected: Alias _PK in ProjectionExpression too
            response = table.scan(
                ProjectionExpression="#w, random_id, #gpk_attr_name", # <<< ALIAS _PK here
                ExpressionAttributeNames={
                    "#w": "word",
                    "#gpk_attr_name": "_PK" # <<< Define alias for _PK
                },
                **scan_args
            )
            items = response.get('Items', [])
            total_scanned += len(items)

            for item in items:
                # Check if _PK or random_id already exists to avoid re-updating
                if '_PK' not in item or 'random_id' not in item:
                    word = item['word']
                    gsi_pk = "FIVE_LETTER_WORD"
                    random_id = Decimal(str(random.random()))

                    try:
                        table.update_item(
                            Key={'word': word},
                            UpdateExpression="SET #rid = :val1, #gpk = :val2",
                            ExpressionAttributeNames={
                                '#rid': 'random_id',
                                '#gpk': '_PK'
                            },
                            ExpressionAttributeValues={
                                ':val1': random_id,
                                ':val2': gsi_pk
                            }
                        )
                        total_updated += 1
                        if total_updated % 100 == 0:
                            print(f"Progress: Updated {total_updated} items...")
                    except Exception as update_e:
                        print(f"Error updating item '{word}': {update_e}", file=sys.stderr)
                else:
                    pass

            last_evaluated_key = response.get('LastEvaluatedKey')
            if not last_evaluated_key:
                break
        except Exception as scan_e:
            print(f"Error during scan or update: {scan_e}", file=sys.stderr)
            sys.exit(1)

    print(f"\nFinished updating items. Total items scanned: {total_scanned}. Total items actually updated (or re-processed): {total_updated}.")
    print("Please verify a few items in your DynamoDB console to ensure 'random_id' and '_PK' are present.")

if __name__ == "__main__":
    start_time = time.time()
    add_random_id_to_items()
    end_time = time.time()
    print(f"Script completed in {end_time - start_time:.2f} seconds.")
    