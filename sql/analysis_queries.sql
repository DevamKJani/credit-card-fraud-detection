-- Credit Card Fraud Detection - Analysis Queries
-- This script contains various queries for analyzing credit card fraud data

USE CreditCardFraud;
GO

-- 1. Overall fraud statistics
SELECT
    COUNT(*) AS total_transactions,
    SUM(CAST(class AS INT)) AS actual_fraud_count,
    SUM(CAST(predicted_fraud AS INT)) AS predicted_fraud_count,
    CAST(SUM(CAST(class AS INT)) AS FLOAT) / COUNT(*) * 100 AS actual_fraud_percentage,
    CAST(SUM(CAST(predicted_fraud AS INT)) AS FLOAT) / COUNT(*) * 100 AS predicted_fraud_percentage,
    AVG(fraud_probability) AS avg_fraud_probability
FROM
    Transactions;
GO

-- 2. Model performance metrics
SELECT * FROM Model_Performance;
GO

-- 3. Hourly transaction patterns
SELECT * FROM Hourly_Fraud_Stats
ORDER BY hour_of_day;
GO

-- 4. Transaction amount statistics by fraud status
SELECT
    CASE WHEN class = 1 THEN 'Fraudulent' ELSE 'Legitimate' END AS transaction_type,
    COUNT(*) AS transaction_count,
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount,
    AVG(amount) AS avg_amount,
    STDEV(amount) AS stdev_amount
FROM
    Transactions
GROUP BY
    class;
GO

-- 5. Risk category distribution
SELECT
    CASE
        WHEN fraud_probability < 0.3 THEN 'Low Risk'
        WHEN fraud_probability < 0.7 THEN 'Medium Risk'
        ELSE 'High Risk'
    END AS risk_category,
    COUNT(*) AS transaction_count,
    SUM(CAST(class AS INT)) AS actual_fraud_count,
    CAST(SUM(CAST(class AS INT)) AS FLOAT) / COUNT(*) * 100 AS fraud_rate
FROM
    Transactions
GROUP BY
    CASE
        WHEN fraud_probability < 0.3 THEN 'Low Risk'
        WHEN fraud_probability < 0.7 THEN 'Medium Risk'
        ELSE 'High Risk'
    END
ORDER BY
    CASE risk_category
        WHEN 'Low Risk' THEN 1
        WHEN 'Medium Risk' THEN 2
        WHEN 'High Risk' THEN 3
    END;
GO

-- 6. False positive analysis
SELECT
    t.transaction_id,
    t.transaction_date,
    t.amount,
    t.fraud_probability,
    DATEPART(HOUR, t.transaction_date) AS hour_of_day
FROM
    Transactions t
    JOIN Fraud_Predictions p ON t.transaction_id = p.transaction_id
WHERE
    p.is_false_positive = 1
ORDER BY
    t.fraud_probability DESC;
GO

-- 7. False negative analysis
SELECT
    t.transaction_id,
    t.transaction_date,
    t.amount,
    t.fraud_probability,
    DATEPART(HOUR, t.transaction_date) AS hour_of_day
FROM
    Transactions t
    JOIN Fraud_Predictions p ON t.transaction_id = p.transaction_id
WHERE
    p.is_false_negative = 1
ORDER BY
    t.fraud_probability ASC;
GO

-- 8. Stored procedure for transactions by hour
CREATE OR ALTER PROCEDURE GetTransactionsByHour
    @HourOfDay INT = NULL
AS
BEGIN
    IF @HourOfDay IS NULL
    BEGIN
        -- Return all hours if no specific hour is provided
        SELECT
            DATEPART(HOUR, transaction_date) AS hour_of_day,
            COUNT(*) AS transaction_count,
            SUM(CAST(class AS INT)) AS fraud_count,
            CAST(SUM(CAST(class AS INT)) AS FLOAT) / COUNT(*) * 100 AS fraud_percentage,
            AVG(amount) AS avg_amount
        FROM
            Transactions
        GROUP BY
            DATEPART(HOUR, transaction_date)
        ORDER BY
            hour_of_day;
    END
    ELSE
    BEGIN
        -- Return details for the specified hour
        SELECT
            transaction_id,
            transaction_date,
            amount,
            class,
            predicted_fraud,
            fraud_probability
        FROM
            Transactions
        WHERE
            DATEPART(HOUR, transaction_date) = @HourOfDay
        ORDER BY
            fraud_probability DESC;
    END
END;
GO

-- 9. Stored procedure for high-risk transactions
CREATE OR ALTER PROCEDURE GetHighRiskTransactions
    @RiskThreshold DECIMAL(10, 6) = 0.7,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL
AS
BEGIN
    SELECT
        t.transaction_id,
        t.transaction_date,
        t.amount,
        t.fraud_probability,
        CASE
            WHEN t.class = 1 AND t.predicted_fraud = 1 THEN 'True Positive'
            WHEN t.class = 0 AND t.predicted_fraud = 1 THEN 'False Positive'
            WHEN t.class = 1 AND t.predicted_fraud = 0 THEN 'False Negative'
            ELSE 'True Negative'
        END AS prediction_result
    FROM
        Transactions t
    WHERE
        t.fraud_probability >= @RiskThreshold
        AND (@StartDate IS NULL OR t.transaction_date >= @StartDate)
        AND (@EndDate IS NULL OR t.transaction_date <= @EndDate)
    ORDER BY
        t.fraud_probability DESC;
END;
GO

-- 10. Stored procedure for model performance by amount range
CREATE OR ALTER PROCEDURE GetModelPerformanceByAmountRange
AS
BEGIN
    -- Define amount ranges and analyze model performance within each range
    WITH AmountRanges AS (
        SELECT
            transaction_id,
            CASE
                WHEN amount < 10 THEN '< $10'
                WHEN amount < 50 THEN '$10 - $49.99'
                WHEN amount < 100 THEN '$50 - $99.99'
                WHEN amount < 500 THEN '$100 - $499.99'
                WHEN amount < 1000 THEN '$500 - $999.99'
                ELSE '$1000+'
            END AS amount_range,
            class,
            predicted_fraud
        FROM
            Transactions
    ),
    PerformanceByRange AS (
        SELECT
            amount_range,
            COUNT(*) AS transaction_count,
            SUM(CAST(class AS INT)) AS actual_fraud_count,
            SUM(CAST(predicted_fraud AS INT)) AS predicted_fraud_count,
            SUM(CASE WHEN class = 1 AND predicted_fraud = 1 THEN 1 ELSE 0 END) AS true_positive,
            SUM(CASE WHEN class = 0 AND predicted_fraud = 0 THEN 1 ELSE 0 END) AS true_negative,
            SUM(CASE WHEN class = 0 AND predicted_fraud = 1 THEN 1 ELSE 0 END) AS false_positive,
            SUM(CASE WHEN class = 1 AND predicted_fraud = 0 THEN 1 ELSE 0 END) AS false_negative
        FROM
            AmountRanges
        GROUP BY
            amount_range
    )
    SELECT
        amount_range,
        transaction_count,
        actual_fraud_count,
        CAST(actual_fraud_count AS FLOAT) / transaction_count * 100 AS actual_fraud_percentage,
        CAST(true_positive + true_negative AS FLOAT) / transaction_count * 100 AS accuracy,
        CASE WHEN (true_positive + false_positive) > 0 
            THEN CAST(true_positive AS FLOAT) / (true_positive + false_positive) * 100 
            ELSE 0 END AS precision_pct,
        CASE WHEN (true_positive + false_negative) > 0
            THEN CAST(true_positive AS FLOAT) / (true_positive + false_negative) * 100
            ELSE 0 END AS recall_pct
    FROM
        PerformanceByRange
    ORDER BY
        CASE amount_range
            WHEN '< $10' THEN 1
            WHEN '$10 - $49.99' THEN 2
            WHEN '$50 - $99.99' THEN 3
            WHEN '$100 - $499.99' THEN 4
            WHEN '$500 - $999.99' THEN 5
            WHEN '$1000+' THEN 6
        END;
END;
GO

-- Test the stored procedures
EXEC GetTransactionsByHour;
GO

EXEC GetHighRiskTransactions @RiskThreshold = 0.9;
GO

EXEC GetModelPerformanceByAmountRange;
GO

-- 11. Create index for better performance
CREATE INDEX IX_Transactions_TransactionDate ON Transactions(transaction_date);
CREATE INDEX IX_Transactions_FraudProbability ON Transactions(fraud_probability);
GO

PRINT 'Analysis queries created successfully.';
GO