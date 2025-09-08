About this file (E-Commerce-Dataset)
The data set belongs to a leading online E-Commerce company. An online retail (E commerce) company wants to know the customers who are going to churn, so accordingly they can approach customer to offer some promos.

That means:

Target column = Churn (1 → churn, 0 → stay).

Feature columns = Tenure, Login device, Payment mode, Gender, Time spent, Orders, Coupons, etc.

Business goal = predict which customers are at risk of leaving so the company can retain them with promos.

🔹 Implications for Cleaning

Since this is for churn analysis, how we treat missing values like Tenure matters:

Tenure is very important →

If Tenure is missing, it may mean the company didn’t record it (not that the customer has 0).

Dropping rows with missing Tenure might remove valuable churn data.

Better: impute with median tenure within the same customer group (e.g., by CityTier or SatisfactionScore).

Numerical columns (like CouponUsed, OrderCount, DaySinceLastOrder) →

Missing values could mean 0 usage (not truly missing).

Business check: if CouponUsed is NULL, should it be treated as 0?

Categorical columns (like PreferredPaymentMode, Gender) →

Fill missing values with the most frequent category (mode).