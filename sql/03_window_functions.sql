-- ============================================================
-- 03_window_functions.sql
-- This file exists specifically to prove window function fluency —
-- the single most-tested SQL skill in technical interviews that
-- pandas-only analysts usually can't do.
--
-- A window function lets you compute something "across a set of rows
-- related to the current row" WITHOUT collapsing those rows into one
-- (unlike GROUP BY, which collapses). That's the core concept to be able
-- to explain out loud in an interview.
-- ============================================================

-- Q10: Rank customers by MonthlyCharges within their contract type
-- WHY: RANK() lets you answer "who are the top N in each group" in one
-- query instead of looping per group in Python.
SELECT
    customerID,
    Contract,
    MonthlyCharges,
    RANK() OVER (PARTITION BY Contract ORDER BY MonthlyCharges DESC) AS charge_rank_in_contract
FROM customers
ORDER BY Contract, charge_rank_in_contract
LIMIT 30;


-- Q11: Running (cumulative) count of churned customers ordered by tenure
-- WHY: Simulates "if customers churned in order of tenure, how does
-- cumulative churn build up?" — a classic SUM() OVER pattern.
SELECT
    tenure,
    customerID,
    Churn,
    SUM(Churn) OVER (ORDER BY tenure) AS cumulative_churned
FROM customers
ORDER BY tenure
LIMIT 50;


-- Q12: Each customer's MonthlyCharges vs the average for their segment
-- WHY: AVG() OVER (PARTITION BY ...) keeps every row but adds a
-- group-level benchmark next to it — useful for spotting outliers
-- without losing row-level detail (which GROUP BY would do).
SELECT
    customerID,
    Contract,
    InternetService,
    MonthlyCharges,
    ROUND(AVG(MonthlyCharges) OVER (PARTITION BY Contract, InternetService), 2) AS segment_avg_charges,
    ROUND(MonthlyCharges - AVG(MonthlyCharges) OVER (PARTITION BY Contract, InternetService), 2) AS diff_from_segment_avg
FROM customers
ORDER BY diff_from_segment_avg DESC
LIMIT 20;


-- Q13: Percentile rank of tenure (NTILE) — split customers into quartiles
-- WHY: NTILE is how you build quartile/decile segments for marketing or
-- risk-scoring without manually picking bucket boundaries.
SELECT
    customerID,
    tenure,
    NTILE(4) OVER (ORDER BY tenure) AS tenure_quartile
FROM customers;


-- Q14: Quartile-level churn rate (combining Q13 logic with aggregation)
-- WHY: A CTE (WITH clause) lets us build the quartile first, then
-- aggregate on top of it — this two-stage pattern (window fn → aggregate)
-- is extremely common in real analytics SQL.
WITH tenure_quartiles AS (
    SELECT
        customerID,
        tenure,
        Churn,
        NTILE(4) OVER (ORDER BY tenure) AS tenure_quartile
    FROM customers
)
SELECT
    tenure_quartile,
    COUNT(*) AS num_customers,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2) AS churn_rate_pct
FROM tenure_quartiles
GROUP BY tenure_quartile
ORDER BY tenure_quartile;
