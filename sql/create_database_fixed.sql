-- Credit Card Fraud Detection - Database Creation Script (FIXED VERSION)
-- This script creates the database and tables for storing credit card transaction data

-- Create database
USE master;
GO

-- Drop database if it exists
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'CreditCardFraud')
BEGIN
    ALTER DATABASE CreditCardFraud SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CreditCardFraud;
END
GO

CREATE DATABASE CreditCardFraud;
GO

USE CreditCardFraud;
GO

-- Create Transactions table to store main transaction details
CREATE TABLE Transactions (
    transaction_id VARCHAR(50) PRIMARY KEY,  -- Increased to VARCHAR(50)
    transaction_date DATETIME NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    class BIT NOT NULL,                    -- 0 = legitimate, 1 = fraudulent
    predicted_fraud BIT NOT NULL,          -- 0 = predicted legitimate, 1 = predicted fraudulent
    fraud_probability DECIMAL(10, 6) NOT NULL,
    created_at DATETIME DEFAULT GETDATE()
);
GO

-- Create Transaction_Features table to store feature details
CREATE TABLE Transaction_Features (
    transaction_id VARCHAR(50) PRIMARY KEY,  -- Increased to VARCHAR(50)
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
    v28 DECIMAL(18, 10) NULL,
    CONSTRAINT FK_Features_Transactions FOREIGN KEY (transaction_id) 
        REFERENCES Transactions(transaction_id)
);
GO

-- Create Fraud_Predictions table to store prediction details
CREATE TABLE Fraud_Predictions (
    transaction_id VARCHAR(50) PRIMARY KEY,  -- Increased to VARCHAR(50)
    fraud_probability DECIMAL(10, 6) NOT NULL,
    predicted_fraud BIT NOT NULL,
    is_false_positive BIT NOT NULL,
    is_false_negative BIT NOT NULL,
    CONSTRAINT FK_Predictions_Transactions FOREIGN KEY (transaction_id) 
        REFERENCES Transactions(transaction_id)
);
GO

-- Create Risk_Categories table to define risk levels
CREATE TABLE Risk_Categories (
    risk_id INT PRIMARY KEY,
    risk_name VARCHAR(20) NOT NULL,
    min_probability DECIMAL(10, 6) NOT NULL,
    max_probability DECIMAL(10, 6) NOT NULL
);
GO

-- Insert predefined risk categories
INSERT INTO Risk_Categories (risk_id, risk_name, min_probability, max_probability)
VALUES 
    (1, 'Low Risk', 0.0, 0.3),
    (2, 'Medium Risk', 0.3, 0.7),
    (3, 'High Risk', 0.7, 1.0);
GO

-- Create view for transaction summary
CREATE VIEW Transaction_Summary AS
SELECT 
    t.transaction_id,
    t.transaction_date,
    t.amount,
    t.class,
    t.predicted_fraud,
    t.fraud_probability,
    CASE
        WHEN t.fraud_probability < 0.3 THEN 'Low Risk'
        WHEN t.fraud_probability < 0.7 THEN 'Medium Risk'
        ELSE 'High Risk'
    END AS risk_category,
    p.is_false_positive,
    p.is_false_negative,
    DATEPART(HOUR, t.transaction_date) AS transaction_hour,
    DATEPART(DAY, t.transaction_date) AS transaction_day,
    DATEPART(MONTH, t.transaction_date) AS transaction_month
FROM 
    Transactions t
    JOIN Fraud_Predictions p ON t.transaction_id = p.transaction_id;
GO

-- Create view for hourly fraud statistics
CREATE VIEW Hourly_Fraud_Stats AS
SELECT 
    DATEPART(HOUR, transaction_date) AS hour_of_day,
    COUNT(*) AS transaction_count,
    SUM(CAST(class AS INT)) AS actual_fraud_count,
    SUM(CAST(predicted_fraud AS INT)) AS predicted_fraud_count,
    AVG(fraud_probability) AS avg_fraud_probability
FROM 
    Transactions
GROUP BY 
    DATEPART(HOUR, transaction_date);
GO

-- Create view for model performance
CREATE VIEW Model_Performance AS
SELECT
    SUM(CASE WHEN class = 0 AND predicted_fraud = 0 THEN 1 ELSE 0 END) AS true_negative,
    SUM(CASE WHEN class = 1 AND predicted_fraud = 1 THEN 1 ELSE 0 END) AS true_positive,
    SUM(CASE WHEN class = 0 AND predicted_fraud = 1 THEN 1 ELSE 0 END) AS false_positive,
    SUM(CASE WHEN class = 1 AND predicted_fraud = 0 THEN 1 ELSE 0 END) AS false_negative,
    CAST(SUM(CASE WHEN class = predicted_fraud THEN 1 ELSE 0 END) AS FLOAT) / NULLIF(COUNT(*), 0) AS accuracy,
    CAST(SUM(CASE WHEN class = 1 AND predicted_fraud = 1 THEN 1 ELSE 0 END) AS FLOAT) / 
        NULLIF(SUM(CASE WHEN predicted_fraud = 1 THEN 1 ELSE 0 END), 0) AS precision,
    CAST(SUM(CASE WHEN class = 1 AND predicted_fraud = 1 THEN 1 ELSE 0 END) AS FLOAT) / 
        NULLIF(SUM(CASE WHEN class = 1 THEN 1 ELSE 0 END), 0) AS recall
FROM
    Transactions;
GO

PRINT 'Database and tables created successfully.';
GO