-- ============================================================
-- 01_foundational_queries.sql
-- Basic aggregations and segment breakdowns
--
-- WHY START HERE: Before fancy window functions, you need to show you
-- can answer the bread-and-butter business questions: "what's the churn
-- rate, and how does it vary by group?" This is 80% of real analyst work.
-- ============================================================

-- Q1: Overall churn rate
-- WHY: This is the single most important number in the whole project —
-- every other analysis is "what changes this number, for which group?"
SELECT
    COUNT(*) AS total_customers,
    SUM(Churn) AS churned_customers,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2) AS churn_rate_pct
FROM customers;


-- Q2: Churn rate by contract type
-- WHY: Tests a real hypothesis — month-to-month customers should churn more
-- than 1-2 year contract customers because they have no commitment.
SELECT
    Contract,
    COUNT(*) AS num_customers,
    SUM(Churn) AS num_churned,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2) AS churn_rate_pct
FROM customers
GROUP BY Contract
ORDER BY churn_rate_pct DESC;


-- Q3: Churn rate by internet service type
SELECT
    InternetService,
    COUNT(*) AS num_customers,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges
FROM customers
GROUP BY InternetService
ORDER BY churn_rate_pct DESC;


-- Q4: Revenue at risk from churned customers
-- WHY: Translates a churn % into a dollar number — this is the kind of
-- query a stakeholder actually asks for ("how much money are we losing?").
SELECT
    SUM(CASE WHEN Churn = 1 THEN MonthlyCharges ELSE 0 END) AS monthly_revenue_lost,
    ROUND(SUM(CASE WHEN Churn = 1 THEN MonthlyCharges ELSE 0 END) * 12, 2) AS annualized_revenue_lost
FROM customers;


-- Q5: Multi-dimensional segment: contract type x payment method
-- WHY: Real churn drivers are rarely single-variable. This shows you can
-- slice across two dimensions at once.
SELECT
    Contract,
    PaymentMethod,
    COUNT(*) AS num_customers,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2) AS churn_rate_pct
FROM customers
GROUP BY Contract, PaymentMethod
HAVING COUNT(*) >= 30   -- filter out tiny, noisy segments
ORDER BY churn_rate_pct DESC;


-- Q6: Which add-on services correlate with retention?
-- WHY: Tests whether selling more services ("stickiness") reduces churn.
SELECT
    TechSupport,
    OnlineSecurity,
    COUNT(*) AS num_customers,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2) AS churn_rate_pct
FROM customers
GROUP BY TechSupport, OnlineSecurity
ORDER BY churn_rate_pct DESC;
