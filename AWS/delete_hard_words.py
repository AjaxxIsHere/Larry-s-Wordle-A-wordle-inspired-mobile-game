import boto3

# --- Configuration ---
AWS_REGION = 'us-east-1'  # e.g., 'us-east-1'
TABLE_NAME = 'WordleWords' # Replace with your DynamoDB table name
NEW_EASY_WORDS_FILE = '' # Path to your new text file with easy words
PRIMARY_KEY_ATTRIBUTE = 'word' # The name of the primary key attribute in your DynamoDB table

# --- Initialize DynamoDB client ---
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
table = dynamodb.Table(TABLE_NAME)

def load_easy_words(filepath):
    """Loads words from the new easy words text file."""
    try:
        with open(filepath, 'r') as f:
            # Read words, strip whitespace, convert to lowercase, and filter out empty lines
            words = {line.strip().lower() for line in f if line.strip()}
        print(f"Loaded {len(words)} easy words from '{filepath}'.")
        return words
    except FileNotFoundError:
        print(f"Error: The file '{filepath}' was not found.")
        return set()
    except Exception as e:
        print(f"An error occurred while loading easy words: {e}")
        return set()

def get_all_db_words():
    """Scans the DynamoDB table and returns all words."""
    db_words = set()
    try:
        response = table.scan(
            ProjectionExpression=PRIMARY_KEY_ATTRIBUTE
        )
        for item in response['Items']:
            if PRIMARY_KEY_ATTRIBUTE in item:
                db_words.add(item[PRIMARY_KEY_ATTRIBUTE].lower())

        while 'LastEvaluatedKey' in response:
            response = table.scan(
                ProjectionExpression=PRIMARY_KEY_ATTRIBUTE,
                ExclusiveStartKey=response['LastEvaluatedKey']
            )
            for item in response['Items']:
                if PRIMARY_KEY_ATTRIBUTE in item:
                    db_words.add(item[PRIMARY_KEY_ATTRIBUTE].lower())

        print(f"Found {len(db_words)} words in the DynamoDB table '{TABLE_NAME}'.")
        return db_words
    except Exception as e:
        print(f"An error occurred while scanning DynamoDB table: {e}")
        return set()

def delete_words_from_db(words_to_delete):
    """Deletes specified words from the DynamoDB table."""
    if not words_to_delete:
        print("No words to delete.")
        return

    print(f"Attempting to delete {len(words_to_delete)} words from the database...")
    deleted_count = 0
    errors_count = 0

    for word in words_to_delete:
        try:
            table.delete_item(
                Key={
                    PRIMARY_KEY_ATTRIBUTE: word
                }
            )
            print(f"Successfully deleted: {word}")
            deleted_count += 1
        except Exception as e:
            print(f"Error deleting '{word}': {e}")
            errors_count += 1
    
    print(f"Deletion complete. Successfully deleted {deleted_count} words. Encountered {errors_count} errors.")


if __name__ == "__main__":
    # 1. Load the new easy words list
    easy_words = load_easy_words(NEW_EASY_WORDS_FILE)
    if not easy_words:
        print("Cannot proceed without a valid list of easy words. Exiting.")
    else:
        # 2. Get all words currently in the database
        all_db_words = get_all_db_words()
        
        if not all_db_words:
            print("No words found in the database. Nothing to delete. Exiting.")
        else:
            # 3. Determine which words in the DB are NOT in the easy list
            words_to_delete = all_db_words - easy_words
            
            if words_to_delete:
                print("\nWords to be deleted from the database:")
                for word in sorted(list(words_to_delete)):
                    print(f"- {word}")
                
                confirmation = input("\nAre you sure you want to proceed with deleting these words? (yes/no): ").lower()
                if confirmation == 'yes':
                    delete_words_from_db(words_to_delete)
                    print("\nDeletion process initiated.")
                else:
                    print("Deletion cancelled by user.")
            else:
                print("All words in the database are already in the new easy words list. No deletions needed.")