-- Credit Card Fraud Detection - Data Import Script (FIXED VERSION)
-- This script imports the CSV data into the SQL database

USE CreditCardFraud;
GO

-- Enable bulk loading
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
GO
RECONFIGURE;
GO

-- Create a temporary table to hold transaction data
CREATE TABLE #TempTransactions (
    transaction_id VARCHAR(50),  -- Increased to VARCHAR(50)
    transaction_date VARCHAR(30),
    amount DECIMAL(10, 2),
    class BIT,
    predicted_fraud BIT,
    fraud_probability DECIMAL(10, 6)
);
GO

-- Import from transactions.csv
-- Replace the file path with your actual path
DECLARE @TransactionsCSV VARCHAR(500) = 'D:\Projects\credit-card-fraud-detection\exports\transactions.csv';
DECLARE @TransactionsSQL NVARCHAR(1000);

SET @TransactionsSQL = '
BULK INSERT #TempTransactions
FROM ''' + @TransactionsCSV + '''
WITH (
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);';

EXEC sp_executesql @TransactionsSQL;
GO

-- Insert data from temporary table into Transactions table
INSERT INTO Transactions (transaction_id, transaction_date, amount, class, predicted_fraud, fraud_probability)
SELECT 
    transaction_id,
    CONVERT(DATETIME, transaction_date, 120),
    amount,
    class,
    predicted_fraud,
    fraud_probability
FROM 
    #TempTransactions;
GO

-- Drop temporary table
DROP TABLE #TempTransactions;
GO

-- Create a temporary table to hold feature data
CREATE TABLE #TempFeatures (
    transaction_id VARCHAR(50),  -- Increased to VARCHAR(50)
    v1 DECIMAL(18, 10) NULL,
    v2 DECIMAL(18, 10) NULL,
    v3 DECIMAL(18, 10) NULL,
    v4 DECIMAL(18, 10) NULL,
    v5 DECIMAL(18, 10) NULL,
    v6 DECIMAL(18, 10) NULL,
    v7 DECIMAL(18, 10) NULL,
    v8 DECIMAL(18, 10) NULL,
    v9 DECIMAL(18, 10) NULL,
    v10 DECIMAL(18, 10) NULL,
    v11 DECIMAL(18, 10) NULL,
    v12 DECIMAL(18, 10) NULL,
    v13 DECIMAL(18, 10) NULL,
    v14 DECIMAL(18, 10) NULL,
    v15 DECIMAL(18, 10) NULL,
    v16 DECIMAL(18, 10) NULL,
    v17 DECIMAL(18, 10) NULL,
    v18 DECIMAL(18, 10) NULL,
    v19 DECIMAL(18, 10) NULL,
    v20 DECIMAL(18, 10) NULL,
    v21 DECIMAL(18, 10) NULL,
    v22 DECIMAL(18, 10) NULL,
    v23 DECIMAL(18, 10) NULL,
    v24 DECIMAL(18, 10) NULL,
    v25 DECIMAL(18, 10) NULL,
    v26 DECIMAL(18, 10) NULL,
    v27 DECIMAL(18, 10) NULL,
    v28 DECIMAL(18, 10) NULL
);
GO

-- Import from transaction_features.csv
-- Replace the file path with your actual path
DECLARE @FeaturesCSV VARCHAR(500) = 'D:\Projects\credit-card-fraud-detection\exports\transaction_features.csv';
DECLARE @FeaturesSQL NVARCHAR(1000);

SET @FeaturesSQL = '
BULK INSERT #TempFeatures
FROM ''' + @FeaturesCSV + '''
WITH (
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);';

EXEC sp_executesql @FeaturesSQL;
GO

-- Insert data from temporary table into Transaction_Features table
INSERT INTO Transaction_Features
SELECT * FROM #TempFeatures;
GO

-- Drop temporary table
DROP TABLE #TempFeatures;
GO

-- Create a temporary table to hold prediction data
CREATE TABLE #TempPredictions (
    transaction_id VARCHAR(50),  -- Increased to VARCHAR(50)
    fraud_probability DECIMAL(10, 6),
    predicted_fraud BIT,
    is_false_positive BIT,
    is_false_negative BIT
);
GO

-- Import from fraud_predictions.csv
-- Replace the file path with your actual path
DECLARE @PredictionsCSV VARCHAR(500) = 'D:\Projects\credit-card-fraud-detection\exports\fraud_predictions.csv';
DECLARE @PredictionsSQL NVARCHAR(1000);

SET @PredictionsSQL = '
BULK INSERT #TempPredictions
FROM ''' + @PredictionsCSV + '''
WITH (
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);';

EXEC sp_executesql @PredictionsSQL;
GO

-- Insert data from temporary table into Fraud_Predictions table
INSERT INTO Fraud_Predictions
SELECT * FROM #TempPredictions;
GO

-- Drop temporary table
DROP TABLE #TempPredictions;
GO

-- Count records in each table for verification
SELECT 'Transactions' AS TableName, COUNT(*) AS RecordCount FROM Transactions
UNION ALL
SELECT 'Transaction_Features' AS TableName, COUNT(*) AS RecordCount FROM Transaction_Features
UNION ALL
SELECT 'Fraud_Predictions' AS TableName, COUNT(*) AS RecordCount FROM Fraud_Predictions;
GO

PRINT 'Data import completed successfully.';
GO