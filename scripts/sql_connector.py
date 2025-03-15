"""
SQL Database Connection and Operations for Credit Card Fraud Detection
This script provides functions to connect to the SQL database and retrieve data.
"""

import pandas as pd
import pyodbc
import os
import logging
from datetime import datetime

# Set up logging
log_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'logs')
os.makedirs(log_dir, exist_ok=True)
log_file = os.path.join(log_dir, 'sql_operations.log')

logging.basicConfig(
    filename=log_file,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Database connection parameters
SERVER = 'localhost\SQLEXPRESS'  # Update with your SQL Server instance name
DATABASE = 'CreditCardFraud'
DRIVER = 'SQL Server'  # SQL Server driver for Windows

def get_connection_string():
    """Get the connection string for SQL Server using Windows Authentication."""
    return f'DRIVER={{{DRIVER}}};SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes;'

def test_connection():
    """Test the connection to the SQL database."""
    try:
        conn_str = get_connection_string()
        conn = pyodbc.connect(conn_str)
        logging.info("Successfully connected to the database")
        print("Successfully connected to the database")
        conn.close()
        return True
    except Exception as e:
        logging.error(f"Error connecting to the database: {e}")
        print(f"Error connecting to the database: {e}")
        return False

def execute_query(query, params=None):
    """Execute a SQL query and return the results as a DataFrame."""
    try:
        conn_str = get_connection_string()
        conn = pyodbc.connect(conn_str)
        
        if params:
            df = pd.read_sql(query, conn, params=params)
        else:
            df = pd.read_sql(query, conn)
            
        conn.close()
        return df
    except Exception as e:
        logging.error(f"Error executing query: {e}")
        print(f"Error executing query: {e}")
        return pd.DataFrame()

def execute_stored_procedure(procedure_name, params=None):
    """Execute a stored procedure and return the results as a DataFrame."""
    try:
        conn_str = get_connection_string()
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        
        if params:
            cursor.execute(f"EXEC {procedure_name} {params}")
        else:
            cursor.execute(f"EXEC {procedure_name}")
            
        # Get results
        results = cursor.fetchall()
        columns = [column[0] for column in cursor.description]
        df = pd.DataFrame.from_records(results, columns=columns)
        
        conn.close()
        return df
    except Exception as e:
        logging.error(f"Error executing stored procedure: {e}")
        print(f"Error executing stored procedure: {e}")
        return pd.DataFrame()

def get_overall_fraud_statistics():
    """Get the overall fraud statistics from the database."""
    query = """
    SELECT
        COUNT(*) AS total_transactions,
        SUM(CAST(class AS INT)) AS actual_fraud_count,
        SUM(CAST(predicted_fraud AS INT)) AS predicted_fraud_count,
        CAST(SUM(CAST(class AS INT)) AS FLOAT) / COUNT(*) * 100 AS actual_fraud_percentage,
        CAST(SUM(CAST(predicted_fraud AS INT)) AS FLOAT) / COUNT(*) * 100 AS predicted_fraud_percentage,
        AVG(fraud_probability) AS avg_fraud_probability
    FROM
        Transactions
    """
    return execute_query(query)

def get_model_performance():
    """Get the model performance metrics from the database."""
    query = "SELECT * FROM Model_Performance"
    return execute_query(query)

def get_hourly_transaction_patterns():
    """Get hourly transaction patterns from the database."""
    return execute_stored_procedure("GetTransactionsByHour")

def get_high_risk_transactions(risk_threshold=0.7):
    """Get high-risk transactions from the database."""
    return execute_stored_procedure(
        "GetHighRiskTransactions", 
        f"@RiskThreshold = {risk_threshold}"
    )

def get_model_performance_by_amount():
    """Get model performance by amount range from the database."""
    return execute_stored_procedure("GetModelPerformanceByAmountRange")

def get_transaction_details(transaction_id):
    """Get details for a specific transaction."""
    query = """
    SELECT 
        t.transaction_id,
        t.transaction_date,
        t.amount,
        t.class,
        t.predicted_fraud,
        t.fraud_probability,
        p.is_false_positive,
        p.is_false_negative
    FROM 
        Transactions t
        JOIN Fraud_Predictions p ON t.transaction_id = p.transaction_id
    WHERE 
        t.transaction_id = ?
    """
    return execute_query(query, (transaction_id,))

def get_transactions_by_risk_category(risk_category):
    """Get transactions by risk category."""
    query = """
    SELECT 
        t.transaction_id,
        t.transaction_date,
        t.amount,
        t.class,
        t.predicted_fraud,
        t.fraud_probability
    FROM 
        Transactions t
    WHERE 
    """
    
    if risk_category.lower() == 'low':
        query += "t.fraud_probability < 0.3"
    elif risk_category.lower() == 'medium':
        query += "t.fraud_probability >= 0.3 AND t.fraud_probability < 0.7"
    elif risk_category.lower() == 'high':
        query += "t.fraud_probability >= 0.7"
    else:
        raise ValueError("Risk category must be 'low', 'medium', or 'high'")
    
    query += " ORDER BY t.fraud_probability"
    
    if risk_category.lower() == 'high':
        query += " DESC"
        
    return execute_query(query)

def export_to_excel(query_function, file_name, *args, **kwargs):
    """Execute a query function and export the results to Excel."""
    try:
        # Execute the query function with any provided arguments
        df = query_function(*args, **kwargs)
        
        if df.empty:
            logging.warning(f"No data returned for export to {file_name}")
            print(f"No data returned for export to {file_name}")
            return False
        
        # Create the exports directory if it doesn't exist
        export_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'sql_exports')
        os.makedirs(export_dir, exist_ok=True)
        
        # Create the full file path
        file_path = os.path.join(export_dir, file_name)
        
        # Export to Excel
        df.to_excel(file_path, index=False)
        logging.info(f"Data exported successfully to {file_path}")
        print(f"Data exported successfully to {file_path}")
        return True
    except Exception as e:
        logging.error(f"Error exporting to Excel: {e}")
        print(f"Error exporting to Excel: {e}")
        return False

def insert_transaction(transaction_data):
    """Insert a new transaction into the database."""
    try:
        conn_str = get_connection_string()
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        
        # Insert into Transactions table
        cursor.execute("""
        INSERT INTO Transactions 
        (transaction_id, transaction_date, amount, class, predicted_fraud, fraud_probability)
        VALUES (?, ?, ?, ?, ?, ?)
        """, 
        (
            transaction_data['transaction_id'],
            transaction_data['transaction_date'],
            transaction_data['amount'],
            transaction_data['class'],
            transaction_data['predicted_fraud'],
            transaction_data['fraud_probability']
        ))
        
        conn.commit()
        conn.close()
        
        logging.info(f"Transaction {transaction_data['transaction_id']} inserted successfully")
        return True
    except Exception as e:
        logging.error(f"Error inserting transaction: {e}")
        print(f"Error inserting transaction: {e}")
        return False

def main():
    """Main function to demonstrate SQL connection and operations."""
    print("Credit Card Fraud Detection - SQL Database Operations")
    print("=" * 60)
    
    # Test the connection
    if not test_connection():
        return
    
    # Demonstrate some basic queries
    print("\nOverall Fraud Statistics:")
    stats_df = get_overall_fraud_statistics()
    if not stats_df.empty:
        print(stats_df)
        
    print("\nModel Performance Metrics:")
    perf_df = get_model_performance()
    if not perf_df.empty:
        print(perf_df)
    
    print("\nHourly Transaction Patterns:")
    hourly_df = get_hourly_transaction_patterns()
    if not hourly_df.empty:
        print(hourly_df.head())
    
    # Export some data to Excel
    export_to_excel(get_hourly_transaction_patterns, "hourly_patterns.xlsx")
    export_to_excel(get_high_risk_transactions, "high_risk_transactions.xlsx", 0.9)
    export_to_excel(get_model_performance_by_amount, "performance_by_amount.xlsx")
    
    print("\nData exports completed. Check the 'sql_exports' directory.")

if __name__ == "__main__":
    main()