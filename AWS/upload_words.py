import boto3
import os
import sys
import time

# --- Configuration ---
# Make sure this matches your DynamoDB table name for ALL words
DYNAMODB_TABLE_NAME = 'WordleWords'
# Make sure this matches the name of your word list file
WORD_LIST_FILE = 'words.txt'
# Your AWS region (e.g., 'us-east-1')
AWS_REGION = 'us-east-1'

# --- Initialize DynamoDB client ---
# boto3 will automatically use credentials from `aws configure`
# or environment variables.
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
table = dynamodb.Table(DYNAMODB_TABLE_NAME)

print(f"Attempting to upload words to DynamoDB table: {DYNAMODB_TABLE_NAME} in region {AWS_REGION}")

def upload_word_to_dynamodb(word_to_add):
    try:
        # Check if the word already exists to prevent duplicates (optional, but good)
        response = table.get_item(
            Key={'word': word_to_add}
        )
        if 'Item' in response:
            return f"Skipped: Word '{word_to_add}' already exists."

        # If not exists, put the item
        table.put_item(
            Item={'word': word_to_add}
        )
        return f"Added: {word_to_add}"
    except Exception as e:
        return f"Error adding '{word_to_add}': {e}"

def upload_words_batch(words):
    # Use batch_writer for efficient bulk loading
    # It handles buffering items and retrying failed requests.
    success_count = 0
    skipped_count = 0
    error_count = 0
    failed_words = []

    with table.batch_writer() as batch:
        for word in words:
            word_lower = word.strip().lower() # Clean and lowercase the word

            if not word_lower: # Skip empty lines
                continue

            if len(word_lower) != 5: # Optional: only add 5-letter words
                print(f"Warning: Skipping '{word_lower}' - not a 5-letter word.")
                continue

            try:
                # Check if the word already exists - batch_writer itself doesn't check
                # We can use get_item here if we absolutely want to avoid put_item on existing
                # But if primary key is 'word', put_item on existing just overwrites with same data, which is harmless.
                # For performance, for a one-time load, it's often fine to just put_item.
                # If you want to strictly prevent overwrites or check, you'd uncomment get_item or use condition expressions.
                # For simplicity, we'll just put_item for now. If you ran it twice, it would just re-put them.

                batch.put_item(
                    Item={'word': word_lower}
                )
                success_count += 1
            except Exception as e:
                error_count += 1
                failed_words.append(word_lower)
                print(f"Error adding '{word_lower}' to batch: {e}", file=sys.stderr)

    return success_count, skipped_count, error_count, failed_words

if __name__ == "__main__":
    if not os.path.exists(WORD_LIST_FILE):
        print(f"Error: Word list file '{WORD_LIST_FILE}' not found in the same directory.", file=sys.stderr)
        sys.exit(1)

    words_to_upload = []
    try:
        with open(WORD_LIST_FILE, 'r') as f:
            for line in f:
                word = line.strip().lower()
                if len(word) == 5 and word.isalpha(): # Basic validation
                    words_to_upload.append(word)
    except Exception as e:
        print(f"Error reading word list file: {e}", file=sys.stderr)
        sys.exit(1)

    if not words_to_upload:
        print("No 5-letter words found in the file to upload.", file=sys.stderr)
        sys.exit(0)

    print(f"Found {len(words_to_upload)} 5-letter words to attempt to upload.")
    print("Starting upload process. This may take a few moments...")

    start_time = time.time()

    # Using batch_writer for efficiency
    success, skipped, errors, failed_list = upload_words_batch(words_to_upload)

    end_time = time.time()
    duration = end_time - start_time

    print("\n--- Upload Summary ---")
    print(f"Total words attempted: {len(words_to_upload)}")
    print(f"Successfully added/updated: {success}")
    # print(f"Skipped (already existed): {skipped}") # Batch writer overwrites, so skip is not tracked this way
    print(f"Errors during batching: {errors}")
    if failed_list:
        print(f"Words that failed: {', '.join(failed_list[:10])}{'...' if len(failed_list) > 10 else ''}")
    print(f"Total time taken: {duration:.2f} seconds")

    print("\nVerification: Check your DynamoDB table in the AWS Console to see the words.")