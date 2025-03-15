"""
Data cleaning and preprocessing for credit card fraud detection.
"""

import pandas as pd
import numpy as np
import os
import logging
from datetime import datetime
from config import *

# Set up logging
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def load_raw_data():
    """Load the raw credit card transaction data."""
    try:
        logging.info(f"Loading raw data from {RAW_DATA_FILE}")
        df = pd.read_csv(RAW_DATA_FILE)
        logging.info(f"Loaded data with shape: {df.shape}")
        return df
    except Exception as e:
        logging.error(f"Error loading raw data: {e}")
        raise

def check_data_quality(df):
    """Check data quality and log issues."""
    logging.info("Checking data quality...")
    
    # Check for missing values
    missing_values = df.isnull().sum()
    if missing_values.sum() > 0:
        logging.warning(f"Missing values found: {missing_values[missing_values > 0]}")
    else:
        logging.info("No missing values found")
    
    # Check for duplicates
    duplicates = df.duplicated().sum()
    if duplicates > 0:
        logging.warning(f"Found {duplicates} duplicate rows")
    else:
        logging.info("No duplicate rows found")
    
    # Check class distribution
    class_counts = df[TARGET].value_counts()
    fraud_ratio = class_counts[1] / class_counts[0]
    logging.info(f"Class distribution - Legitimate: {class_counts[0]}, Fraud: {class_counts[1]}")
    logging.info(f"Fraud ratio: {fraud_ratio:.6f}")
    
    # Check for outliers in Amount
    q1 = df['Amount'].quantile(0.25)
    q3 = df['Amount'].quantile(0.75)
    iqr = q3 - q1
    upper_bound = q3 + 1.5 * iqr
    outliers = df[df['Amount'] > upper_bound].shape[0]
    logging.info(f"Found {outliers} outliers in Amount column")
    
    return {
        'missing_values': missing_values.sum(),
        'duplicates': duplicates,
        'fraud_ratio': fraud_ratio,
        'amount_outliers': outliers
    }

def preprocess_data(df):
    """Preprocess the data for modeling."""
    logging.info("Starting data preprocessing...")
    
    # Create a copy to avoid modifying the original
    processed_df = df.copy()
    
    # Normalize Time feature
    processed_df['Time'] = processed_df['Time'] / (60 * 60 * 24)  # Convert to days
    logging.info("Normalized Time feature to represent days")
    
    # Convert Time to hours of day and create cyclic features
    hours = (processed_df['Time'] * 24) % 24
    processed_df['Hour_Sin'] = np.sin(2 * np.pi * hours / 24)
    processed_df['Hour_Cos'] = np.cos(2 * np.pi * hours / 24)
    logging.info("Added cyclic time features")
    
    # Log-transform Amount to handle skewness
    processed_df['Amount_Log'] = np.log1p(processed_df['Amount'])
    logging.info("Log-transformed Amount feature")
    
    # Scale numeric features
    v_features_mean = processed_df[V_FEATURES].mean()
    v_features_std = processed_df[V_FEATURES].std()
    
    amount_mean = processed_df['Amount_Log'].mean()
    amount_std = processed_df['Amount_Log'].std()
    
    processed_df['Amount_Scaled'] = (processed_df['Amount_Log'] - amount_mean) / amount_std
    
    # Keep the original features for now
    logging.info("Scaled Amount feature")
    
    # Create a flag for potential outliers
    processed_df['Amount_Outlier'] = (processed_df['Amount'] > upper_bound).astype(int)
    logging.info("Added outlier flag for Amount")
    
    # Calculate additional metrics that might be useful
    processed_df['V_Sum'] = processed_df[V_FEATURES].sum(axis=1)
    processed_df['V_Mean'] = processed_df[V_FEATURES].mean(axis=1)
    processed_df['V_Std'] = processed_df[V_FEATURES].std(axis=1)
    logging.info("Added aggregate features for V columns")
    
    return processed_df

def save_processed_data(df):
    """Save the processed data to CSV."""
    try:
        logging.info(f"Saving processed data to {CLEANED_DATA_FILE}")
        df.to_csv(CLEANED_DATA_FILE, index=False)
        logging.info(f"Saved processed data with shape: {df.shape}")
        
        # Also save a lightweight version with only essential columns for Excel
        essential_columns = ['Time', 'Amount', 'Amount_Scaled', 'Amount_Log', 
                            'Hour_Sin', 'Hour_Cos', 'V_Sum', 'V_Mean', 'V_Std', 
                            'Class', 'Amount_Outlier']
        df_excel = df[essential_columns]
        excel_file = os.path.join(PROCESSED_DATA_DIR, 'creditcard_excel.csv')
        df_excel.to_csv(excel_file, index=False)
        logging.info(f"Saved lightweight version for Excel with {len(essential_columns)} columns")
        
        return True
    except Exception as e:
        logging.error(f"Error saving processed data: {e}")
        return False

def export_data_profile(df):
    """Export a data profile report in HTML format."""
    try:
        from pandas_profiling import ProfileReport
        
        logging.info("Generating data profile report...")
        profile = ProfileReport(df, title="Credit Card Fraud Detection - Data Profile", 
                               minimal=True, explorative=True)
        
        report_dir = os.path.join(ROOT_DIR, 'reports')
        os.makedirs(report_dir, exist_ok=True)
        report_file = os.path.join(report_dir, 'data_profile.html')
        
        profile.to_file(report_file)
        logging.info(f"Data profile report saved to {report_file}")
        return True
    except ImportError:
        logging.warning("pandas-profiling not installed. Skipping profile generation.")
        return False
    except Exception as e:
        logging.error(f"Error generating data profile: {e}")
        return False

def main():
    """Main function to execute the data cleaning pipeline."""
    start_time = datetime.now()
    logging.info(f"Data cleaning process started at {start_time}")
    
    try:
        # Load data
        df = load_raw_data()
        
        # Check data quality
        quality_metrics = check_data_quality(df)
        
        # Preprocess data
        processed_df = preprocess_data(df)
        
        # Save processed data
        save_processed_data(processed_df)
        
        # Try to export profile
        try:
            import pandas_profiling
            export_data_profile(df)
        except ImportError:
            logging.warning("pandas-profiling not installed. Install with: pip install pandas-profiling")
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        logging.info(f"Data cleaning completed successfully in {duration:.2f} seconds")
        print(f"Data cleaning completed successfully. See {LOG_FILE} for details.")
        
    except Exception as e:
        logging.error(f"Error in data cleaning pipeline: {e}")
        print(f"Error in data cleaning pipeline: {e}")

if __name__ == "__main__":
    # Create missing variables needed in the script
    # Calculate upper bound for outliers (used in preprocess_data)
    df_temp = pd.read_csv(RAW_DATA_FILE)
    q1 = df_temp['Amount'].quantile(0.25)
    q3 = df_temp['Amount'].quantile(0.75)
    iqr = q3 - q1
    upper_bound = q3 + 1.5 * iqr
    
    main()