"""
Export processed data and model predictions for SQL and Excel analysis.
This script prepares data in formats optimized for database import and Excel analysis.
"""

import pandas as pd
import numpy as np
import os
import logging
import joblib
from datetime import datetime
from config import *

# Set up logging
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def load_model_and_test_data():
    """Load the best model and test data."""
    try:
        # Load the best model
        model_path = MODEL_FILE
        logging.info(f"Loading model from {model_path}")
        model = joblib.load(model_path)
        
        # Load test data
        test_data_path = TEST_DATA_FILE
        logging.info(f"Loading test data from {test_data_path}")
        test_df = pd.read_csv(test_data_path)
        
        return model, test_df
    except Exception as e:
        logging.error(f"Error loading model or test data: {e}")
        raise

def create_export_directory():
    """Create directory for exported data."""
    export_dir = os.path.join(ROOT_DIR, 'exports')
    os.makedirs(export_dir, exist_ok=True)
    return export_dir

def export_for_sql(model, test_df, export_dir):
    """Export data for SQL database import."""
    logging.info("Preparing data export for SQL database...")
    
    try:
        # Preprocess test data as needed for the model
        # (Same preprocessing as done during training)
        selected_features = [col for col in test_df.columns if col.startswith('V') or 
                            col in ['Amount_Scaled', 'Hour_Sin', 'Hour_Cos', 
                                    'V_Sum', 'V_Mean', 'V_Std']]
        
        X_test = test_df[selected_features]
        
        # Generate predictions
        test_df['fraud_probability'] = model.predict_proba(X_test)[:, 1]
        test_df['predicted_fraud'] = model.predict(X_test)
        
        # Add flags for false positives and negatives
        test_df['is_false_positive'] = ((test_df['predicted_fraud'] == 1) & (test_df['Class'] == 0)).astype(int)
        test_df['is_false_negative'] = ((test_df['predicted_fraud'] == 0) & (test_df['Class'] == 1)).astype(int)
        
        # Format timestamps for SQL
        # Convert the 'Time' column (in seconds) to a proper datetime
        # Assuming 'Time' starts at 0 and represents seconds from the beginning of the dataset
        base_date = datetime(2023, 1, 1)  # Using a dummy base date
        test_df['transaction_date'] = test_df['Time'].apply(
            lambda seconds: (base_date + pd.Timedelta(seconds=float(seconds))).strftime('%Y-%m-%d %H:%M:%S')
        )
        
        # Create a unique transaction ID for the database
        test_df['transaction_id'] = [f"TRANS{i:06d}" for i in range(1, len(test_df) + 1)]
        
        # Prepare SQL-friendly column names
        sql_df = test_df.copy()
        sql_df.columns = [col.lower().replace(' ', '_') for col in sql_df.columns]
        
        # Export full dataset for SQL
        sql_file = os.path.join(export_dir, 'credit_card_transactions_full.csv')
        sql_df.to_csv(sql_file, index=False)
        logging.info(f"Exported full dataset for SQL to {sql_file}")
        
        # Create a transactions table with main transaction info
        transactions_df = sql_df[['transaction_id', 'transaction_date', 'amount', 
                                 'class', 'predicted_fraud', 'fraud_probability']]
        transactions_sql_file = os.path.join(export_dir, 'transactions.csv')
        transactions_df.to_csv(transactions_sql_file, index=False)
        logging.info(f"Exported transactions table to {transactions_sql_file}")
        
        # Create a features table with the V features
        v_features = [col for col in sql_df.columns if col.startswith('v')]
        features_df = sql_df[['transaction_id'] + v_features]
        features_sql_file = os.path.join(export_dir, 'transaction_features.csv')
        features_df.to_csv(features_sql_file, index=False)
        logging.info(f"Exported features table to {features_sql_file}")
        
        # Create a predictions table with detailed prediction info
        predictions_df = sql_df[['transaction_id', 'fraud_probability', 'predicted_fraud', 
                               'is_false_positive', 'is_false_negative']]
        predictions_sql_file = os.path.join(export_dir, 'fraud_predictions.csv')
        predictions_df.to_csv(predictions_sql_file, index=False)
        logging.info(f"Exported predictions table to {predictions_sql_file}")
        
        return {
            'full_data': sql_file,
            'transactions': transactions_sql_file,
            'features': features_sql_file,
            'predictions': predictions_sql_file
        }
    
    except Exception as e:
        logging.error(f"Error preparing SQL export: {e}")
        raise

def export_for_excel(test_df, export_dir):
    """Export data for Excel analysis."""
    logging.info("Preparing data export for Excel analysis...")
    
    try:
        # Create a more Excel-friendly version with fewer columns
        excel_df = test_df[['transaction_id', 'transaction_date', 'Amount', 
                          'fraud_probability', 'predicted_fraud', 'Class',
                          'is_false_positive', 'is_false_negative']].copy()
        
        # Rename columns to be more descriptive
        excel_df.columns = ['Transaction ID', 'Transaction Date', 'Amount', 
                          'Fraud Probability', 'Predicted Fraud', 'Actual Fraud',
                          'False Positive', 'False Negative']
        
        # Add helper columns for Excel analysis
        excel_df['Transaction Hour'] = pd.to_datetime(excel_df['Transaction Date']).dt.hour
        excel_df['Transaction Day'] = pd.to_datetime(excel_df['Transaction Date']).dt.day_name()
        
        # Add a risk category column
        conditions = [
            (excel_df['Fraud Probability'] < 0.3),
            (excel_df['Fraud Probability'] >= 0.3) & (excel_df['Fraud Probability'] < 0.7),
            (excel_df['Fraud Probability'] >= 0.7)
        ]
        choices = ['Low Risk', 'Medium Risk', 'High Risk']
        excel_df['Risk Category'] = np.select(conditions, choices, default='Unknown')
        
        # Export to CSV for Excel
        excel_file = os.path.join(export_dir, 'fraud_analysis_for_excel.csv')
        excel_df.to_csv(excel_file, index=False)
        logging.info(f"Exported Excel analysis file to {excel_file}")
        
        # Create a pivot table for fraud by hour
        hour_pivot = pd.pivot_table(
            excel_df, 
            values=['Fraud Probability', 'Transaction ID'],
            index='Transaction Hour',
            aggfunc={
                'Fraud Probability': 'mean',
                'Transaction ID': 'count'
            }
        ).reset_index()
        
        hour_pivot.columns = ['Hour', 'Average Fraud Probability', 'Transaction Count']
        hour_pivot_file = os.path.join(export_dir, 'fraud_by_hour.csv')
        hour_pivot.to_csv(hour_pivot_file, index=False)
        logging.info(f"Exported hour pivot table to {hour_pivot_file}")
        
        # Create a summary of risk categories
        risk_summary = excel_df['Risk Category'].value_counts().reset_index()
        risk_summary.columns = ['Risk Category', 'Count']
        risk_summary_file = os.path.join(export_dir, 'risk_summary.csv')
        risk_summary.to_csv(risk_summary_file, index=False)
        logging.info(f"Exported risk summary to {risk_summary_file}")
        
        return {
            'excel_main': excel_file,
            'hour_pivot': hour_pivot_file,
            'risk_summary': risk_summary_file
        }
    
    except Exception as e:
        logging.error(f"Error preparing Excel export: {e}")
        raise

def export_for_power_bi(test_df, export_dir):
    """Export data optimized for Power BI dashboard."""
    logging.info("Preparing data export for Power BI...")
    
    try:
        # Create a copy of the dataframe for Power BI
        powerbi_df = test_df.copy()
        
        # Format columns appropriately
        powerbi_df['Transaction_Date'] = pd.to_datetime(powerbi_df['transaction_date'])
        powerbi_df['Transaction_Year'] = powerbi_df['Transaction_Date'].dt.year
        powerbi_df['Transaction_Month'] = powerbi_df['Transaction_Date'].dt.month
        powerbi_df['Transaction_Day'] = powerbi_df['Transaction_Date'].dt.day
        powerbi_df['Transaction_Hour'] = powerbi_df['Transaction_Date'].dt.hour
        powerbi_df['Transaction_DayOfWeek'] = powerbi_df['Transaction_Date'].dt.day_name()
        
        # Create a model performance flag
        powerbi_df['Model_Performance'] = 'Correct Prediction'
        powerbi_df.loc[powerbi_df['is_false_positive'] == 1, 'Model_Performance'] = 'False Positive'
        powerbi_df.loc[powerbi_df['is_false_negative'] == 1, 'Model_Performance'] = 'False Negative'
        
        # Create risk bins for easier visualization
        powerbi_df['Risk_Score'] = pd.cut(
            powerbi_df['fraud_probability'], 
            bins=[0, 0.2, 0.4, 0.6, 0.8, 1.0],
            labels=['Very Low', 'Low', 'Medium', 'High', 'Very High']
        )
        
        # Export for Power BI
        powerbi_file = os.path.join(export_dir, 'fraud_detection_powerbi.csv')
        powerbi_df.to_csv(powerbi_file, index=False)
        logging.info(f"Exported Power BI data to {powerbi_file}")
        
        return powerbi_file
    
    except Exception as e:
        logging.error(f"Error preparing Power BI export: {e}")
        raise

def write_export_summary(sql_exports, excel_exports, powerbi_export, export_dir):
    """Write a summary of all exports for documentation."""
    summary_file = os.path.join(export_dir, 'export_summary.md')
    
    with open(summary_file, 'w') as f:
        f.write("# Credit Card Fraud Detection - Data Export Summary\n\n")
        f.write(f"Export Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        
        f.write("## SQL Database Exports\n\n")
        f.write("The following files are prepared for SQL database import:\n\n")
        for name, path in sql_exports.items():
            f.write(f"- **{name}**: `{os.path.basename(path)}`\n")
        
        f.write("\n## Excel Analysis Exports\n\n")
        f.write("The following files are prepared for Excel analysis:\n\n")
        for name, path in excel_exports.items():
            f.write(f"- **{name}**: `{os.path.basename(path)}`\n")
        
        f.write("\n## Power BI Export\n\n")
        f.write(f"- **Power BI Dataset**: `{os.path.basename(powerbi_export)}`\n\n")
        
        f.write("## Usage Instructions\n\n")
        f.write("### SQL Database\n\n")
        f.write("1. Use the `transactions.csv`, `transaction_features.csv`, and `fraud_predictions.csv` files to create separate tables in your database.\n")
        f.write("2. The `transaction_id` field can be used as the primary key to join these tables.\n")
        f.write("3. Alternatively, import the full dataset from `credit_card_transactions_full.csv` if you prefer a denormalized structure.\n\n")
        
        f.write("### Excel Analysis\n\n")
        f.write("1. Open the `fraud_analysis_for_excel.csv` file in Excel for interactive analysis.\n")
        f.write("2. Use the `fraud_by_hour.csv` and `risk_summary.csv` files for quick insights or to create pivot tables.\n")
        f.write("3. Create charts and visualizations using the provided risk categories and flags.\n\n")
        
        f.write("### Power BI\n\n")
        f.write("1. Import the `fraud_detection_powerbi.csv` file into Power BI.\n")
        f.write("2. This file includes all the necessary fields with appropriate formatting for creating interactive dashboards.\n")
        f.write("3. Use the time-based fields for time series analysis and the risk score for color-coded visualizations.\n")
    
    logging.info(f"Export summary written to {summary_file}")
    return summary_file

def main():
    """Main function to execute the data export pipeline."""
    start_time = datetime.now()
    logging.info(f"Data export process started at {start_time}")
    
    try:
        # Load model and test data
        model, test_df = load_model_and_test_data()
        
        # Create export directory
        export_dir = create_export_directory()
        
        # Export for SQL
        sql_exports = export_for_sql(model, test_df, export_dir)
        
        # Export for Excel
        excel_exports = export_for_excel(test_df, export_dir)
        
        # Export for Power BI
        powerbi_export = export_for_power_bi(test_df, export_dir)
        
        # Write summary
        summary_file = write_export_summary(sql_exports, excel_exports, powerbi_export, export_dir)
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        logging.info(f"Data export completed successfully in {duration:.2f} seconds")
        print(f"Data export completed successfully.")
        print(f"Exports saved to {export_dir}")
        print(f"See {summary_file} for details")
        
    except Exception as e:
        logging.error(f"Error in data export pipeline: {e}")
        print(f"Error in data export pipeline: {e}")

if __name__ == "__main__":
    main()