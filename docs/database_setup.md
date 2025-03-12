# SQL Database Setup for Credit Card Fraud Detection

This document provides instructions for setting up the SQL Server database for the credit card fraud detection system on Windows.

## Prerequisites

- Windows 10 or 11
- SQL Server Express installed (free version)
- SQL Server Management Studio (SSMS) installed
- sqlcmd utility installed (comes with SQL Server Express)

## Installation Steps

### 1. Install SQL Server Express

1. Download SQL Server Express from [Microsoft's website](https://www.microsoft.com/en-us/sql-server/sql-server-downloads)
2. Run the installer and select "Basic" installation type
3. Make note of the instance name (typically `SQLEXPRESS`)
4. Ensure Windows Authentication is enabled

### 2. Install SQL Server Management Studio

1. Download SSMS from [Microsoft's website](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms)
2. Run the installer with default settings

## Database Setup

### Using the Automated Script

1. Open Command Prompt as Administrator
2. Navigate to the project's SQL directory:
   ```
   cd path\to\credit-card-fraud-detection\sql
   ```
3. Run the setup batch file:
   ```
   run_sql_setup.bat
   ```
4. This will create the database, tables, and import the data automatically.

### Manual Setup Using SQL Server Management Studio

If you prefer to set up the database manually:

1. Open SQL Server Management Studio (SSMS)
2. Connect to your local SQL Server instance:
   - Server name: `localhost\SQLEXPRESS` (or your instance name)
   - Authentication: Windows Authentication
3. Execute the SQL scripts in the following order:
   - `create_database.sql` - Creates the database and tables
   - `import_data.sql` - Imports the data from CSV files
   - `analysis_queries.sql` - Sets up analysis queries and stored procedures

## Database Structure

The database consists of the following tables:

1. **Transactions** - Main transaction details:
   - transaction_id (PK)
   - transaction_date
   - amount
   - class (actual fraud status: 0=legitimate, 1=fraudulent)
   - predicted_fraud
   - fraud_probability

2. **Transaction_Features** - PCA-transformed transaction features:
   - transaction_id (PK, FK)
   - v1 through v28 (the anonymized features)

3. **Fraud_Predictions** - Details about fraud predictions:
   - transaction_id (PK, FK)
   - fraud_probability
   - predicted_fraud
   - is_false_positive
   - is_false_negative

4. **Risk_Categories** - Defined risk levels:
   - risk_id (PK)
   - risk_name
   - min_probability
   - max_probability

### Views

The database also includes the following views:

1. **Transaction_Summary** - Combines transaction data with risk categories and prediction results
2. **Hourly_Fraud_Stats** - Aggregates transaction statistics by hour of day
3. **Model_Performance** - Provides overall model performance metrics

### Stored Procedures

The following stored procedures are available:

1. **GetTransactionsByHour** - Get transactions for a specific hour or all hours
2. **GetHighRiskTransactions** - Get transactions above a specified risk threshold
3. **GetModelPerformanceByAmountRange** - Analyze model performance by transaction amount ranges

## Connecting from Python

Use the `sql_connector.py` script in the `scripts` directory to connect to the database from Python.

### Example:

```python
from sql_connector import test_connection, get_overall_fraud_statistics

# Test the connection
test_connection()

# Get fraud statistics
stats_df = get_overall_fraud_statistics()
print(stats_df)
```

## Troubleshooting

### Connection Issues

If you encounter connection issues:

1. Verify SQL Server is running:
   - Open Services (services.msc)
   - Check if "SQL Server (SQLEXPRESS)" is running
   - If not, start the service

2. Check your instance name:
   - The default is `SQLEXPRESS`
   - If you installed with a different name, update the connection string in the scripts

3. Verify Windows Authentication:
   - Make sure you're running the scripts as a user with access to SQL Server
   - Try running Command Prompt or PowerShell as Administrator

### Import Issues

If data import fails:

1. Verify the file paths in `import_data.sql` match your actual CSV file locations
2. Check if the CSV files exist and have the expected format
3. Ensure the SQL Server service account has access to the CSV files

## Next Steps

After setting up the database, you can:

1. Use SQL Server Management Studio to explore the data
2. Run the analysis queries to gain insights into fraud patterns
3. Connect from Python to perform programmatic data access
4. Connect from Excel to create reports
5. Connect from Power BI to build dashboards