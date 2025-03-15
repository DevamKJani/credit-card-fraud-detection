# Fraud Overview Dashboard

## Worksheet Structure

1. **Overview Tab**
   - Title: "Credit Card Fraud Detection - Overview Dashboard"
   - Last Updated: [Current Date Formula]
   - Key Metrics:
     - Total Transactions: [COUNT formula]
     - Fraud Transactions: [COUNT with criteria]
     - Fraud Rate: [PERCENTAGE formula]
     - False Positives: [COUNT with criteria]
     - False Negatives: [COUNT with criteria]
     
   - Charts:
     - Fraud Distribution Pie Chart (Legitimate vs. Fraudulent)
     - Daily Transaction Volume Chart
     - Model Performance Metrics Chart (Precision, Recall, Accuracy)

2. **Transaction Analysis Tab**
   - Transaction Summary Table with conditional formatting
   - Risk Score Distribution Chart
   - Amount Range Distribution Table
   - Top 10 Highest-Risk Transactions Table

3. **Time Analysis Tab**
   - Hourly Transaction Volume Chart
   - Hourly Fraud Rate Chart
   - Day of Week Transaction Pattern Chart
   - Time-based Heat Map (Hour vs. Day, colored by fraud rate)

## Key Formulas & Features

### 1. Key Metrics Formulas

```
= COUNTIFS(Transactions[predicted_fraud], 1, Transactions[class], 0)  'False Positives
= COUNTIFS(Transactions[predicted_fraud], 0, Transactions[class], 1)  'False Negatives
= SUMIFS(Transactions[amount], Transactions[class], 1) / SUM(Transactions[amount]) * 100  'Fraud Amount %
```

### 2. Conditional Formatting Rules

- Risk Score highlighting:
  - High Risk (≥0.7): Red
  - Medium Risk (0.3-0.7): Yellow
  - Low Risk (<0.3): Green

- Transaction Type highlighting:
  - True Positives: Green
  - True Negatives: Light Green
  - False Positives: Yellow
  - False Negatives: Red

### 3. PivotTable Setup

- Rows: Transaction Hour, Day of Week
- Values: Count of Transactions, Fraud Rate
- Filters: Transaction Amount Range, Prediction Result

### 4. Time Analysis Formulas

```
= AVERAGEIFS(Transactions[fraud_probability], Transactions[hour], [hour_cell])  'Average Risk by Hour
= COUNTIFS(Transactions[class], 1, Transactions[hour], [hour_cell]) / COUNTIFS(Transactions[hour], [hour_cell])  'Actual Fraud Rate by Hour
```

## Instructions

1. Import data from SQL Server or CSV files
2. Update the data connection
3. Refresh all PivotTables and charts
4. Save as a template (.xltx) for future use