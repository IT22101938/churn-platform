-- ============================================================
-- 02_tenure_cohorts.sql
-- Cohort analysis by how long a customer has been with the company
--
-- WHY THIS MATTERS: "Cohort analysis" is a term you'll hear constantly in
-- data/growth roles. The idea: group customers by a shared starting point
-- (here, tenure length) and compare behavior across groups. It usually
-- reveals that risk is NOT evenly distributed across a customer's lifetime.
-- ============================================================

-- Q7: Bucket customers into tenure cohorts, compare churn rate
SELECT
    CASE
        WHEN tenure <= 6 THEN '0-6 months'
        WHEN tenure <= 12 THEN '7-12 months'
        WHEN tenure <= 24 THEN '13-24 months'
        WHEN tenure <= 48 THEN '25-48 months'
        ELSE '49+ months'
    END AS tenure_cohort,
    COUNT(*) AS num_customers,
    SUM(Churn) AS num_churned,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges
FROM customers
GROUP BY tenure_cohort
ORDER BY MIN(tenure);


-- Q8: Within the highest-risk cohort (0-6 months), what's driving churn?
-- WHY: A subquery here lets us scope a second analysis to ONLY the
-- risky cohort identified in Q7, instead of re-running on everyone.
SELECT
    Contract,
    PaymentMethod,
    COUNT(*) AS num_customers,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2) AS churn_rate_pct
FROM (
    SELECT * FROM customers WHERE tenure <= 6
) AS new_customers
GROUP BY Contract, PaymentMethod
ORDER BY churn_rate_pct DESC;


-- Q9: Average tenure of churned vs retained customers
-- WHY: A quick sanity-check style query — confirms the intuitive story
-- (churners leave early) with an actual number, not just a guess.
SELECT
    CASE WHEN Churn = 1 THEN 'Churned' ELSE 'Retained' END AS status,
    COUNT(*) AS num_customers,
    ROUND(AVG(tenure), 1) AS avg_tenure_months,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges
FROM customers
GROUP BY Churn;
