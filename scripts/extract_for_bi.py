"""
Extract data from SQL database for Excel and Power BI
This script extracts data from the SQL database and prepares it for Excel and Power BI.
"""

import pandas as pd
import os
import logging
from datetime import datetime
from sql_connector import (
    test_connection, 
    get_overall_fraud_statistics,
    get_model_performance,
    get_hourly_transaction_patterns,
    get_high_risk_transactions,
    get_model_performance_by_amount,
    execute_query
)

# Set up logging
log_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'logs')
os.makedirs(log_dir, exist_ok=True)
log_file = os.path.join(log_dir, 'extract_for_bi.log')

logging.basicConfig(
    filename=log_file,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def create_export_directory():
    """Create directory for exported data."""
    export_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'bi_exports')
    os.makedirs(export_dir, exist_ok=True)
    return export_dir

def extract_transaction_summary():
    """Extract transaction summary data for reporting."""
    logging.info("Extracting transaction summary...")
    
    query = """
    SELECT * FROM Transaction_Summary
    """
    
    try:
        df = execute_query(query)
        logging.info(f"Extracted {len(df)} rows from Transaction_Summary view")
        return df
    except Exception as e:
        logging.error(f"Error extracting transaction summary: {e}")
        return pd.DataFrame()

def extract_hourly_patterns():
    """Extract hourly transaction patterns."""
    logging.info("Extracting hourly patterns...")
    
    try:
        df = get_hourly_transaction_patterns()
        logging.info(f"Extracted {len(df)} rows of hourly transaction patterns")
        return df
    except Exception as e:
        logging.error(f"Error extracting hourly patterns: {e}")
        return pd.DataFrame()

def extract_risk_distribution():
    """Extract risk distribution data."""
    logging.info("Extracting risk distribution...")
    
    query = """
    SELECT
        CASE
            WHEN fraud_probability < 0.3 THEN 'Low Risk'
            WHEN fraud_probability < 0.7 THEN 'Medium Risk'
            ELSE 'High Risk'
        END AS risk_category,
        COUNT(*) AS transaction_count,
        SUM(CAST(class AS INT)) AS actual_fraud_count,
        SUM(CAST(predicted_fraud AS INT)) AS predicted_fraud_count,
        CAST(SUM(CAST(class AS INT)) AS FLOAT) / COUNT(*) * 100 AS actual_fraud_percentage
    FROM
        Transactions
    GROUP BY
        CASE
            WHEN fraud_probability < 0.3 THEN 'Low Risk'
            WHEN fraud_probability < 0.7 THEN 'Medium Risk'
            ELSE 'High Risk'
        END
    """
    
    try:
        df = execute_query(query)
        logging.info(f"Extracted {len(df)} rows of risk distribution data")
        return df
    except Exception as e:
        logging.error(f"Error extracting risk distribution: {e}")
        return pd.DataFrame()

def extract_amount_distribution():
    """Extract transaction amount distribution."""
    logging.info("Extracting amount distribution...")
    
    query = """
    SELECT
        CASE
            WHEN amount < 10 THEN '< $10'
            WHEN amount < 50 THEN '$10 - $49.99'
            WHEN amount < 100 THEN '$50 - $99.99'
            WHEN amount < 500 THEN '$100 - $499.99'
            WHEN amount < 1000 THEN '$500 - $999.99'
            ELSE '$1000+'
        END AS amount_range,
        COUNT(*) AS transaction_count,
        SUM(CAST(class AS INT)) AS fraud_count,
        CAST(SUM(CAST(class AS INT)) AS FLOAT) / COUNT(*) * 100 AS fraud_percentage
    FROM
        Transactions
    GROUP BY
        CASE
            WHEN amount < 10 THEN '< $10'
            WHEN amount < 50 THEN '$10 - $49.99'
            WHEN amount < 100 THEN '$50 - $99.99'
            WHEN amount < 500 THEN '$100 - $499.99'
            WHEN amount < 1000 THEN '$500 - $999.99'
            ELSE '$1000+'
        END
    """
    
    try:
        df = execute_query(query)
        logging.info(f"Extracted {len(df)} rows of amount distribution data")
        return df
    except Exception as e:
        logging.error(f"Error extracting amount distribution: {e}")
        return pd.DataFrame()

def extract_model_metrics():
    """Extract model performance metrics."""
    logging.info("Extracting model performance metrics...")
    
    try:
        df = get_model_performance()
        logging.info(f"Extracted model performance metrics")
        return df
    except Exception as e:
        logging.error(f"Error extracting model metrics: {e}")
        return pd.DataFrame()

def extract_full_dataset_for_power_bi():
    """Extract a complete dataset for Power BI."""
    logging.info("Extracting complete dataset for Power BI...")
    
    query = """
    SELECT
        t.transaction_id,
        t.transaction_date,
        DATEPART(YEAR, t.transaction_date) AS [Year],
        DATEPART(MONTH, t.transaction_date) AS [Month],
        DATEPART(DAY, t.transaction_date) AS [Day],
        DATEPART(HOUR, t.transaction_date) AS [Hour],
        DATENAME(WEEKDAY, t.transaction_date) AS [DayOfWeek],
        t.amount,
        t.class AS actual_fraud,
        t.predicted_fraud,
        t.fraud_probability,
        CASE
            WHEN t.fraud_probability < 0.3 THEN 'Low Risk'
            WHEN t.fraud_probability < 0.7 THEN 'Medium Risk'
            ELSE 'High Risk'
        END AS risk_category,
        p.is_false_positive,
        p.is_false_negative,
        CASE
            WHEN t.class = 1 AND t.predicted_fraud = 1 THEN 'True Positive'
            WHEN t.class = 0 AND t.predicted_fraud = 0 THEN 'True Negative'
            WHEN t.class = 0 AND t.predicted_fraud = 1 THEN 'False Positive'
            WHEN t.class = 1 AND t.predicted_fraud = 0 THEN 'False Negative'
        END AS prediction_result
    FROM
        Transactions t
        JOIN Fraud_Predictions p ON t.transaction_id = p.transaction_id
    """
    
    try:
        df = execute_query(query)
        logging.info(f"Extracted {len(df)} rows for complete Power BI dataset")
        return df
    except Exception as e:
        logging.error(f"Error extracting complete dataset: {e}")
        return pd.DataFrame()

def create_excel_workbook(export_dir):
    """Create a comprehensive Excel workbook with multiple sheets."""
    logging.info("Creating comprehensive Excel workbook...")
    
    # Create an Excel writer
    file_path = os.path.join(export_dir, 'Fraud_Detection_Report.xlsx')
    writer = pd.ExcelWriter(file_path, engine='xlsxwriter')
    
    try:
        # Get all the data
        stats_df = get_overall_fraud_statistics()
        hourly_df = extract_hourly_patterns()
        risk_df = extract_risk_distribution()
        amount_df = extract_amount_distribution()
        metrics_df = extract_model_metrics()
        performance_by_amount_df = get_model_performance_by_amount()
        high_risk_df = get_high_risk_transactions(0.8)
        
        # Write each dataframe to a different sheet
        stats_df.to_excel(writer, sheet_name='Summary', index=False)
        hourly_df.to_excel(writer, sheet_name='Hourly Patterns', index=False)
        risk_df.to_excel(writer, sheet_name='Risk Distribution', index=False)
        amount_df.to_excel(writer, sheet_name='Amount Distribution', index=False)
        metrics_df.to_excel(writer, sheet_name='Model Metrics', index=False)
        performance_by_amount_df.to_excel(writer, sheet_name='Performance By Amount', index=False)
        high_risk_df.to_excel(writer, sheet_name='High Risk Transactions', index=False)
        
        # Access the workbook and the worksheet objects
        workbook = writer.book
        
        # Add some formatting
        header_format = workbook.add_format({
            'bold': True,
            'text_wrap': True,
            'valign': 'top',
            'fg_color': '#D7E4BC',
            'border': 1
        })
        
        # Apply formatting to each sheet
        for sheet_name in writer.sheets:
            worksheet = writer.sheets[sheet_name]
            
            # Format the header row
            for col_num, value in enumerate(writer.sheets[sheet_name].header_values):
                worksheet.write(0, col_num, value, header_format)
                worksheet.set_column(col_num, col_num, 15)  # Set column width
        
        # Save the workbook
        writer.close()
        logging.info(f"Excel workbook created successfully at {file_path}")
        return True
    except Exception as e:
        logging.error(f"Error creating Excel workbook: {e}")
        try:
            writer.close()
        except:
            pass
        return False

def main():
    """Main function to execute the data extraction pipeline."""
    start_time = datetime.now()
    logging.info(f"Data extraction process started at {start_time}")
    
    print("Credit Card Fraud Detection - Extracting Data for BI Tools")
    print("=" * 60)
    
    # Test the connection
    if not test_connection():
        return
    
    try:
        # Create export directory
        export_dir = create_export_directory()
        
        # Extract individual datasets and save to CSV
        transaction_summary_df = extract_transaction_summary()
        if not transaction_summary_df.empty:
            transaction_summary_df.to_csv(os.path.join(export_dir, 'transaction_summary.csv'), index=False)
            print(f"Saved transaction summary ({len(transaction_summary_df)} rows)")
        
        hourly_patterns_df = extract_hourly_patterns()
        if not hourly_patterns_df.empty:
            hourly_patterns_df.to_csv(os.path.join(export_dir, 'hourly_patterns.csv'), index=False)
            print(f"Saved hourly patterns ({len(hourly_patterns_df)} rows)")
        
        risk_distribution_df = extract_risk_distribution()
        if not risk_distribution_df.empty:
            risk_distribution_df.to_csv(os.path.join(export_dir, 'risk_distribution.csv'), index=False)
            print(f"Saved risk distribution ({len(risk_distribution_df)} rows)")
        
        amount_distribution_df = extract_amount_distribution()
        if not amount_distribution_df.empty:
            amount_distribution_df.to_csv(os.path.join(export_dir, 'amount_distribution.csv'), index=False)
            print(f"Saved amount distribution ({len(amount_distribution_df)} rows)")
        
        model_metrics_df = extract_model_metrics()
        if not model_metrics_df.empty:
            model_metrics_df.to_csv(os.path.join(export_dir, 'model_metrics.csv'), index=False)
            print(f"Saved model metrics")
        
        # Extract a complete dataset for Power BI
        power_bi_df = extract_full_dataset_for_power_bi()
        if not power_bi_df.empty:
            power_bi_df.to_csv(os.path.join(export_dir, 'fraud_detection_for_power_bi.csv'), index=False)
            print(f"Saved complete Power BI dataset ({len(power_bi_df)} rows)")
        
        # Create a comprehensive Excel workbook
        if create_excel_workbook(export_dir):
            print(f"Created comprehensive Excel workbook at {os.path.join(export_dir, 'Fraud_Detection_Report.xlsx')}")
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        logging.info(f"Data extraction completed successfully in {duration:.2f} seconds")
        print(f"\nData extraction completed successfully in {duration:.2f} seconds")
        print(f"All exports saved to {export_dir}")
        
    except Exception as e:
        logging.error(f"Error in data extraction pipeline: {e}")
        print(f"Error in data extraction pipeline: {e}")

if __name__ == "__main__":
    main()