-- ============================================================
-- 04_advanced_queries.sql
-- Subqueries, CTEs, and "what-if" style business questions.
-- ============================================================

-- Q15: Customers whose monthly charge is above the overall average
-- (a correlated-style subquery, the classic "above average" pattern)
SELECT
    customerID,
    MonthlyCharges,
    Contract,
    Churn
FROM customers
WHERE MonthlyCharges > (SELECT AVG(MonthlyCharges) FROM customers)
ORDER BY MonthlyCharges DESC
LIMIT 20;


-- Q16: Segments where churn rate is WORSE than the company-wide average
-- WHY: This is a genuinely useful business query — "show me only the
-- problem segments," not every segment. The subquery computes the
-- benchmark once; HAVING filters groups against it.
WITH segment_churn AS (
    SELECT
        Contract,
        InternetService,
        COUNT(*) AS num_customers,
        AVG(Churn) AS churn_rate
    FROM customers
    GROUP BY Contract, InternetService
)
SELECT
    Contract,
    InternetService,
    num_customers,
    ROUND(churn_rate * 100, 2) AS churn_rate_pct
FROM segment_churn
WHERE churn_rate > (SELECT AVG(Churn) FROM customers)
ORDER BY churn_rate DESC;


-- Q17: "High value at-risk" customers — high spend, no contract lock-in,
-- still active (haven't churned yet). This is exactly the kind of list
-- a retention team would want exported.
SELECT
    customerID,
    MonthlyCharges,
    tenure,
    Contract,
    TechSupport
FROM customers
WHERE Churn = 0
  AND Contract = 'Month-to-month'
  AND MonthlyCharges > (SELECT AVG(MonthlyCharges) FROM customers)
ORDER BY MonthlyCharges DESC
LIMIT 25;


-- Q18: Service adoption count per customer, then churn rate by that count
-- WHY: Demonstrates building a derived metric (number of add-on services)
-- inline with CASE statements, then using it as a grouping variable —
-- shows you can engineer a feature in pure SQL, not just in pandas.
WITH service_counts AS (
    SELECT
        customerID,
        Churn,
        (CASE WHEN OnlineSecurity = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN OnlineBackup = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN DeviceProtection = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN TechSupport = 'Yes' THEN 1 ELSE 0 END) AS num_addon_services
    FROM customers
)
SELECT
    num_addon_services,
    COUNT(*) AS num_customers,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2) AS churn_rate_pct
FROM service_counts
GROUP BY num_addon_services
ORDER BY num_addon_services;


-- Q19: Rank payment methods by churn rate, but only among customers
-- with month-to-month contracts (isolating one variable)
SELECT
    PaymentMethod,
    COUNT(*) AS num_customers,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2) AS churn_rate_pct,
    RANK() OVER (ORDER BY SUM(Churn) * 1.0 / COUNT(*) DESC) AS risk_rank
FROM customers
WHERE Contract = 'Month-to-month'
GROUP BY PaymentMethod;


-- Q20: Full summary table combining everything — one query a stakeholder
-- could actually be handed as a report.
SELECT
    Contract,
    InternetService,
    PaymentMethod,
    COUNT(*) AS num_customers,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(tenure), 1) AS avg_tenure,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges,
    ROUND(SUM(CASE WHEN Churn = 1 THEN MonthlyCharges ELSE 0 END), 2) AS monthly_revenue_at_risk
FROM customers
GROUP BY Contract, InternetService, PaymentMethod
HAVING COUNT(*) >= 20
ORDER BY churn_rate_pct DESC
LIMIT 15;
