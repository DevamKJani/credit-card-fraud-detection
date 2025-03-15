# Credit Card Fraud Detection - Data Export Summary

Export Date: 2025-03-12 16:11:26

## SQL Database Exports

The following files are prepared for SQL database import:

- **full_data**: `credit_card_transactions_full.csv`
- **transactions**: `transactions.csv`
- **features**: `transaction_features.csv`
- **predictions**: `fraud_predictions.csv`

## Excel Analysis Exports

The following files are prepared for Excel analysis:

- **excel_main**: `fraud_analysis_for_excel.csv`
- **hour_pivot**: `fraud_by_hour.csv`
- **risk_summary**: `risk_summary.csv`

## Power BI Export

- **Power BI Dataset**: `fraud_detection_powerbi.csv`

## Usage Instructions

### SQL Database

1. Use the `transactions.csv`, `transaction_features.csv`, and `fraud_predictions.csv` files to create separate tables in your database.
2. The `transaction_id` field can be used as the primary key to join these tables.
3. Alternatively, import the full dataset from `credit_card_transactions_full.csv` if you prefer a denormalized structure.

### Excel Analysis

1. Open the `fraud_analysis_for_excel.csv` file in Excel for interactive analysis.
2. Use the `fraud_by_hour.csv` and `risk_summary.csv` files for quick insights or to create pivot tables.
3. Create charts and visualizations using the provided risk categories and flags.

### Power BI

1. Import the `fraud_detection_powerbi.csv` file into Power BI.
2. This file includes all the necessary fields with appropriate formatting for creating interactive dashboards.
3. Use the time-based fields for time series analysis and the risk score for color-coded visualizations.
