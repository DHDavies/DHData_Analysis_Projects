-- 1. Inspect missing values in important columns
SELECT 
    SUM(CASE WHEN Tenure IS NULL THEN 1 ELSE 0 END) AS Missing_Tenure,
    SUM(CASE WHEN CouponUsed IS NULL THEN 1 ELSE 0 END) AS Missing_CouponUsed,
    SUM(CASE WHEN OrderCount IS NULL THEN 1 ELSE 0 END) AS Missing_OrderCount,
    SUM(CASE WHEN DaySinceLastOrder IS NULL THEN 1 ELSE 0 END) AS Missing_DaySinceLastOrder,
    SUM(CASE WHEN PreferredPaymentMode IS NULL THEN 1 ELSE 0 END) AS Missing_PaymentMode,
    SUM(CASE WHEN Gender IS NULL THEN 1 ELSE 0 END) AS Missing_Gender
FROM ecommerce_data;

-- 2. Fill missing Tenure with median tenure of each CityTier
UPDATE ecommerce_data e
JOIN (
    SELECT CityTier, ROUND(AVG(Tenure),0) AS median_tenure
    FROM ecommerce_data
    WHERE Tenure IS NOT NULL
    GROUP BY CityTier
) c ON e.CityTier = c.CityTier
SET e.Tenure = c.median_tenure
WHERE e.Tenure IS NULL;

-- 3. Fill missing numerical fields with 0 (assuming no activity = 0)
UPDATE ecommerce_data SET CouponUsed = 0 WHERE CouponUsed IS NULL;
UPDATE ecommerce_data SET OrderCount = 0 WHERE OrderCount IS NULL;
UPDATE ecommerce_data SET DaySinceLastOrder = 0 WHERE DaySinceLastOrder IS NULL;

-- 4. Standardize categorical values
-- Standardize Gender
UPDATE ecommerce_data
SET Gender = 'Male'
WHERE Gender IN ('M', 'male', 'MALE');

UPDATE ecommerce_data
SET Gender = 'Female'
WHERE Gender IN ('F', 'female', 'FEMALE');

-- Standardize PaymentMode (example: change variants of Credit Card)
UPDATE ecommerce_data
SET PreferredPaymentMode = 'Credit Card'
WHERE PreferredPaymentMode IN ('credit', 'CREDITCARD', 'cc');

-- Fill missing PaymentMode with most common
UPDATE ecommerce_data
SET PreferredPaymentMode = (
    SELECT mode FROM (
        SELECT PreferredPaymentMode AS mode
        FROM ecommerce_data
        WHERE PreferredPaymentMode IS NOT NULL
        GROUP BY PreferredPaymentMode
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS sub
)
WHERE PreferredPaymentMode IS NULL;

-- 5. Exploratory Analysis: Churn Patterns
-- Churn rate overall
SELECT 
    COUNT(*) AS total_customers,
    SUM(Churn) AS churned_customers,
    ROUND(SUM(Churn)*100.0/COUNT(*),2) AS churn_rate_percent
FROM ecommerce_data;

-- Churn by CityTier
SELECT CityTier, 
       COUNT(*) AS total, 
       SUM(Churn) AS churned, 
       ROUND(SUM(Churn)*100.0/COUNT(*),2) AS churn_rate_percent
FROM ecommerce_data
GROUP BY CityTier
ORDER BY churn_rate_percent DESC;

-- Churn by Preferred Payment Mode
SELECT PreferredPaymentMode,
       COUNT(*) AS total,
       SUM(Churn) AS churned,
       ROUND(SUM(Churn)*100.0/COUNT(*),2) AS churn_rate_percent
FROM ecommerce_data
GROUP BY PreferredPaymentMode
ORDER BY churn_rate_percent DESC;

-- Churn by Tenure buckets
SELECT 
    CASE 
        WHEN Tenure < 6 THEN '0-6 months'
        WHEN Tenure BETWEEN 6 AND 12 THEN '6-12 months'
        WHEN Tenure BETWEEN 13 AND 24 THEN '13-24 months'
        ELSE '24+ months'
    END AS tenure_group,
    COUNT(*) AS total,
    SUM(Churn) AS churned,
    ROUND(SUM(Churn)*100.0/COUNT(*),2) AS churn_rate_percent
FROM ecommerce_data
GROUP BY tenure_group
ORDER BY churn_rate_percent DESC;
