# Fraud Detection Model Analysis Template

## Worksheet Structure

1. **Model Performance Tab**
   - Title: "Credit Card Fraud Detection - Model Performance Analysis"
   - Last Updated: [Current Date Formula]
   - Performance Metrics Table:
     - Accuracy
     - Precision
     - Recall
     - F1 Score
     - AUC-ROC
     
   - Charts:
     - Confusion Matrix Visualization
     - ROC Curve Chart
     - Precision-Recall Chart

2. **Threshold Analysis Tab**
   - Threshold Slider (using Form Controls)
   - Performance at Different Thresholds Table:
     - Threshold Values (0.1 to 0.9)
     - True Positives, False Positives, True Negatives, False Negatives
     - Precision, Recall, F1 Score for each threshold
   - Threshold Impact Chart (Line chart showing metrics vs threshold)

3. **Cost Analysis Tab**
   - Cost Parameters:
     - Average Transaction Amount
     - Cost of Investigating a Flagged Transaction
     - Cost of Missing a Fraudulent Transaction
     - Cost per False Positive
     - Cost per False Negative
   - Cost Calculation Table:
     - Total Cost of False Positives
     - Total Cost of False Negatives
     - Total Cost of Fraud Prevention
     - Net Savings From Fraud Detection
   - Cost-Benefit Analysis Chart

## Key Formulas & Features

### 1. Performance Metrics Formulas

```
= COUNTIFS(Transactions[class], 1, Transactions[predicted_fraud], 1) / (COUNTIFS(Transactions[class], 1, Transactions[predicted_fraud], 1) + COUNTIFS(Transactions[class], 0, Transactions[predicted_fraud], 1))  'Precision

= COUNTIFS(Transactions[class], 1, Transactions[predicted_fraud], 1) / (COUNTIFS(Transactions[class], 1, Transactions[predicted_fraud], 1) + COUNTIFS(Transactions[class], 1, Transactions[predicted_fraud], 0))  'Recall

= 2 * (Precision * Recall) / (Precision + Recall)  'F1 Score
```

### 2. Threshold Analysis

```
= COUNTIFS(Transactions[class], 1, Transactions[fraud_probability], ">=" & ThresholdValue)  'True Positives at threshold

= COUNTIFS(Transactions[class], 0, Transactions[fraud_probability], ">=" & ThresholdValue)  'False Positives at threshold
```

### 3. Cost Analysis Formulas

```
= FalsePosCount * CostPerFalsePos  'Total False Positive Cost

= FalseNegCount * AvgFraudAmount * CostMultiplierFalseNeg  'Total False Negative Cost

= NetSavings / TotalPotentialFraudCost * 100  'ROI Percentage
```

### 4. Visualization Features

- Confusion Matrix as a 2x2 table with conditional formatting
- Interactive threshold slider using Form Controls
- Sparklines showing trend of metrics across thresholds

## Data Tables

1. **Confusion Matrix Table**
   - 2x2 grid showing TP, FP, TN, FN with conditional formatting
   - Percentage calculations for each cell

2. **Threshold Comparison Table**
   - Rows: Threshold values from 0.1 to 0.9
   - Columns: TP, FP, TN, FN, Precision, Recall, F1, Cost

3. **Cost-Benefit Breakdown Table**
   - Rows: Different cost components
   - Columns: Amount, Percentage of Total

## Instructions

1. Import data from SQL or CSV files
2. Set cost parameters based on business knowledge
3. Adjust the threshold slider to see impact on performance metrics
4. Calculate optimal threshold based on cost-benefit analysis
5. Save as template (.xltx) for future usess