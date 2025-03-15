# Transaction Monitoring Report Template

## Worksheet Structure

1. **Daily Monitoring Dashboard**
   - Title: "Credit Card Fraud Detection - Daily Monitoring"
   - Date Filter: [TODAY() formula with dropdown]
   - Daily Summary Metrics:
     - Today's Transaction Count
     - Today's Flagged Transactions
     - Alert Rate (%)
     - Average Risk Score
     - Highest Risk Transaction
     
   - Charts:
     - Today's Transaction Volume by Hour Chart
     - Risk Distribution Pie Chart
     - Flagged Transactions by Amount Range

2. **High-Risk Transaction List**
   - Filterable Table with:
     - Transaction ID
     - Date/Time
     - Amount
     - Risk Score
     - Prediction Result
     - Investigation Status (dropdown: Pending, In Progress, Confirmed Fraud, False Alarm)
     - Notes Field
   - Interactive slicers for filtering by risk score, amount range, and date
   - Conditional formatting to highlight transactions based on risk level

3. **Investigation Tracker**
   - Investigation Summary:
     - Total Cases
     - Pending, In Progress, Completed Cases
     - Fraud Confirmation Rate
     - Average Resolution Time
   - Investigation Table:
     - Transaction Details
     - Assigned To
     - Status
     - Time to Resolution
     - Outcome
     - Notes
   - Summary Chart: Investigation Outcomes

4. **Historical Patterns**
   - Transaction Volume Trend Chart (28-day rolling)
   - Fraud Rate Trend Chart (28-day rolling)
   - Weekly Pattern Chart
   - Monthly Comparison Chart

## Key Formulas & Features

### 1. Date Filtering Formulas

```
= FILTER(Transactions, DATEVALUE(Transactions[transaction_date]) = TODAY())  'Today's Transactions

= AVERAGEIFS(Transactions[fraud_probability], Transactions[transaction_date], TODAY())  'Today's Average Risk
```

### 2. Transaction Monitoring Formulas

```
= MAXIFS(Transactions[fraud_probability], Transactions[transaction_date], TODAY())  'Highest Risk Today

= COUNTIFS(Transactions[transaction_date], TODAY(), Transactions[fraud_probability], ">=0.7")  'High-Risk Count
```

### 3. Investigation Tracking Formulas

```
= AVERAGEIF(InvestigationTable[Status], "Completed", InvestigationTable[Resolution_Time])  'Average Resolution Time

= COUNTIFS(InvestigationTable[Outcome], "Confirmed Fraud") / COUNTIFS(InvestigationTable[Status], "Completed")  'Confirmation Rate
```

### 4. Historical Analysis Formulas

```
= AVERAGEIFS(Transactions[fraud_probability], Transactions[transaction_date], ">="&TODAY()-28, Transactions[transaction_date], "<="&TODAY())  'Rolling 28-Day Average

= AVERAGEIFS(Transactions[fraud_probability], WEEKDAY(Transactions[transaction_date]), WEEKDAY(TODAY()))  'Same Day of Week Average
```

## Data Tables

1. **Today's Transactions Table**
   - Filtered view of transactions for current date
   - Sortable and filterable using Excel tables

2. **High-Risk Queue**
   - All transactions with risk score ≥ 0.7
   - Custom status field with data validation dropdown
   - Action buttons using form controls

3. **Investigation Log**
   - Transaction ID (lookup to main transaction table)
   - Inspector Name (data validation dropdown)
   - Investigation Start Date
   - Resolution Date
   - Resolution Time (calculated)
   - Outcome (data validation dropdown)

## Interactive Elements

1. **Date Navigator**
   - Date picker control
   - Previous/Next buttons for date navigation

2. **Risk Threshold Slider**
   - Adjustable threshold for flagging transactions
   - Dynamic recalculation of flagged count

3. **Status Update Dropdown**
   - Data validation list for investigation status
   - Conditional formatting based on status

4. **Custom KPI Display**
   - Sparklines showing 7-day trend
   - Icon sets for visual indicators (up/down arrows)

## Instructions

1. Connect to SQL database or import CSV data
2. Set the date filter to the desired monitoring date
3. Review the daily summary and high-risk transactions
4. Update investigation statuses as needed
5. Save as template (.xltx) for daily monitoring use