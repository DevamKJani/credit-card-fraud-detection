"""
Credit Card Fraud Detection - Dataset Verification
This script verifies that the Kaggle dataset has been properly downloaded and can be read.
"""

import os
import pandas as pd
import sys
from datetime import datetime

def verify_dataset():
    """Verify the creditcard dataset exists and can be read properly."""
    try:
        # Check if the creditcard.csv file exists
        dataset_path = os.path.join('..', 'data', 'raw', 'creditcard.csv')
        if not os.path.exists(dataset_path):
            print(f"Error: Dataset not found at {dataset_path}")
            print("Please ensure you've downloaded the dataset using the Kaggle API.")
            return False
        
        # Try to read the dataset
        print(f"Reading dataset from {dataset_path}...")
        df = pd.read_csv(dataset_path)
        
        # Print dataset information
        print("\nDataset Summary:")
        print(f"Shape: {df.shape[0]} rows, {df.shape[1]} columns")
        print(f"Columns: {', '.join(df.columns)}")
        
        # Check for fraud distribution
        fraud_count = df['Class'].sum()
        legitimate_count = df.shape[0] - fraud_count
        fraud_percentage = (fraud_count / df.shape[0]) * 100
        
        print("\nClass Distribution:")
        print(f"Legitimate Transactions: {legitimate_count} ({100 - fraud_percentage:.2f}%)")
        print(f"Fraudulent Transactions: {fraud_count} ({fraud_percentage:.2f}%)")
        
        # Create a simple log entry
        log_dir = os.path.join('..', 'logs')
        if not os.path.exists(log_dir):
            os.makedirs(log_dir)
            
        with open(os.path.join(log_dir, 'dataset_verification.log'), 'w') as f:
            f.write(f"Dataset verification completed at {datetime.now()}\n")
            f.write(f"Dataset shape: {df.shape[0]} rows, {df.shape[1]} columns\n")
            f.write(f"Legitimate Transactions: {legitimate_count} ({100 - fraud_percentage:.2f}%)\n")
            f.write(f"Fraudulent Transactions: {fraud_count} ({fraud_percentage:.2f}%)\n")
        
        print("\nVerification completed successfully.")
        return True
    
    except Exception as e:
        print(f"Error during verification: {e}")
        return False

if __name__ == "__main__":
    print("Credit Card Fraud Detection - Dataset Verification")
    print("="*60)
    verify_dataset()