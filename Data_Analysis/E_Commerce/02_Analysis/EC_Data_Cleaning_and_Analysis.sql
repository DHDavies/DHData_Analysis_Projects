-- Create the database (only once)
CREATE DATABASE EC_data_cleaning;
-- Switch to it
USE EC_data_cleaning;
SHOW DATABASES;

-- Inspect missing values.

-- Clean Tenure (impute with group median).

-- Handle missing numerical values (CouponUsed, OrderCount, DaySinceLastOrder).

-- Standardize categorical fields (Gender, PreferredPaymentMode).

-- Do some quick exploratory churn analysis.





SELECT * 
FROM ec_data_cleaning.`e-commerce-dataset`;

-- Create a duplicate table to work on

CREATE TABLE EC_Data
LIKE ec_data_cleaning.`e-commerce-dataset`;

SELECT *
FROM EC_Data;

INSERT EC_Data
SELECT *
FROM ec_data_cleaning.`e-commerce-dataset`;

-- 1. Inspect missing values in important columns
-- Check how Tenure values look
SELECT DISTINCT Tenure
FROM ec_data
ORDER BY Tenure;

-- Check if any Tenure values are empty strings
SELECT COUNT(*) AS Empty_String_Tenure
FROM ec_data
WHERE Tenure = '';

-- Check for placeholders like 'NA' or 'NaN'
SELECT COUNT(*) AS Placeholder_Tenure
FROM ec_data
WHERE Tenure IN ('NA', 'NaN', '?');

-- Since blanks are stored as empty strings (''), 
-- convert them to NULL so you can handle them:

UPDATE ec_data
SET Tenure = NULL
WHERE Tenure = '';

SELECT
    -- Tenure
    SUM(CASE WHEN Tenure IS NULL 
              OR TRIM(Tenure) = '' 
              OR Tenure IN ('NA','NaN','N/A','?') 
             THEN 1 ELSE 0 END) AS Missing_Tenure,

    -- CouponUsed
    SUM(CASE WHEN CouponUsed IS NULL 
              OR TRIM(CouponUsed) = '' 
              OR CouponUsed IN ('NA','NaN','N/A','?') 
             THEN 1 ELSE 0 END) AS Missing_CouponUsed,

    -- OrderCount
    SUM(CASE WHEN OrderCount IS NULL 
              OR TRIM(OrderCount) = '' 
              OR OrderCount IN ('NA','NaN','N/A','?') 
             THEN 1 ELSE 0 END) AS Missing_OrderCount,

    -- DaySinceLastOrder
    SUM(CASE WHEN DaySinceLastOrder IS NULL 
              OR TRIM(DaySinceLastOrder) = '' 
              OR DaySinceLastOrder IN ('NA','NaN','N/A','?') 
             THEN 1 ELSE 0 END) AS Missing_DaySinceLastOrder,

    -- PreferredPaymentMode
    SUM(CASE WHEN PreferredPaymentMode IS NULL 
              OR TRIM(PreferredPaymentMode) = '' 
              OR PreferredPaymentMode IN ('NA','NaN','N/A','?') 
             THEN 1 ELSE 0 END) AS Missing_PaymentMode,

    -- Gender
    SUM(CASE WHEN Gender IS NULL 
              OR TRIM(Gender) = '' 
              OR Gender IN ('NA','NaN','N/A','?') 
             THEN 1 ELSE 0 END) AS Missing_Gender
FROM ec_data;

-- Likely meaning of blank/missing = the customer never used a coupon.
-- Best fix: replace NULL with 0.
-- Meaning of missing = customer has not placed an order yet.
-- In churn prediction, usually we assume missing = inactive (so they haven’t ordered in a long time).

UPDATE ec_data
SET CouponUsed = NULL
WHERE TRIM(CouponUsed) = '';

UPDATE ec_data
SET CouponUsed = 0
WHERE CouponUsed IS NULL;


UPDATE ec_data
SET DaySinceLastOrder = NULL
WHERE TRIM(DaySinceLastOrder) = '';

-- DaySinceLastOrder → use max + 1 (treat as inactive)
-- Find the max value
SELECT MAX(DaySinceLastOrder) AS MaxDays FROM ec_data;

-- Replace NULL values in DaySinceLastOrder with max + 1

UPDATE ec_data
SET DaySinceLastOrder = (
    SELECT max_val 
    FROM (
        SELECT MAX(DaySinceLastOrder) + 1 AS max_val
        FROM ec_data
    ) AS temp
)
WHERE DaySinceLastOrder IS NULL;

SELECT 
    SUM(CASE WHEN CouponUsed IS NULL THEN 1 ELSE 0 END) AS Missing_CouponUsed,
    SUM(CASE WHEN DaySinceLastOrder IS NULL THEN 1 ELSE 0 END) AS Missing_DaySinceLastOrder
FROM ec_data;

SELECT *
FROM ec_data;

-- Standardize categorical fields (Gender, PreferredPaymentMode).


-- **Categorical columns** (like `PreferredPaymentMode`, `Gender`) 
-- → * Fill missing values with the **most frequent category (mode)**.
-- In MySQL, there’s no direct MODE() function, 
-- but we can simulate it using GROUP BY + ORDER BY COUNT().

-- Step 1: Find the most frequent value (mode)

SELECT PreferredPaymentMode, COUNT(*) AS freq
FROM ec_data
WHERE PreferredPaymentMode IS NOT NULL 
  AND TRIM(PreferredPaymentMode) <> '' 
  AND PreferredPaymentMode NOT IN ('NA','NaN','N/A','?')
GROUP BY PreferredPaymentMode
ORDER BY freq DESC
LIMIT 1;

-- 🔹 Step 2: Update missing values with that mode

UPDATE ec_data
SET PreferredPaymentMode = 'Debit Card'
WHERE PreferredPaymentMode IS NULL
   OR TRIM(PreferredPaymentMode) = ''
   OR PreferredPaymentMode IN ('NA','NaN','N/A','?');

-- 🔹 Same for Gender
-- Find mode
SELECT Gender, COUNT(*) AS freq
FROM ec_data
WHERE Gender IS NOT NULL 
  AND TRIM(Gender) <> '' 
  AND Gender NOT IN ('NA','NaN','N/A','?')
GROUP BY Gender
ORDER BY freq DESC
LIMIT 1;

-- Since result = 'Male', update missing
UPDATE ec_data
SET Gender = 'Male'
WHERE Gender IS NULL
   OR TRIM(Gender) = ''
   OR Gender IN ('NA','NaN','N/A','?');

-- Quick exploratory churn analysis.

SELECT *
FROM ec_data;

-- 🔹 1. Overall Churn Rate
SELECT 
	Churn,
    COUNT(*) AS Num_Customers,
    ROUND(COUNT(*) * 100.0/(SELECT COUNT(*) FROM ec_data), 2) AS Pct_Customers
FROM ec_data
GROUP BY Churn;
-- 👉 Tells us what % of customers are churned vs retained.

--  🔹 2. Churn by Tenure (short vs long-term customers)
SELECT
	CASE
		WHEN Tenure <= 6 THEN '0-6 months'
        WHEN Tenure <= 12 THEN '7-12 months'
        WHEN Tenure <= 24 THEN '13-24 months'
        ELSE '25+ months'
	END AS Tenure_Group,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS Churned,
    COUNT(*) AS Total,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Churn_Rate
FROM ec_data
GROUP BY Tenure_Group
ORDER BY Tenure_Group;
-- 👉 Checks if short-tenure customers churn more.

-- 🔹 3. Churn by Coupon Usage







































