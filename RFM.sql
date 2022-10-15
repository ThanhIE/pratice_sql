/* Task 1: Retrieve reports on transaction scenarios and status 
Retrieve a report that includes the following information: customer_id, transaction_id, scenario_id, transaction_type, sub_category, category and status_description. These transactions must meet the following conditions:
Were created in Jan 2020
Status is successful */

SELECT t2020.customer_id
        ,t2020.transaction_id
        ,t2020.scenario_id
        ,transaction_type
        ,sub_category
        ,category
        ,status_description 
FROM fact_transaction_2020 t2020 
JOIN dim_scenario sce ON t2020.scenario_id = sce.scenario_id
JOIN dim_status sta ON t2020.status_id = sta.status_id
WHERE t2020.status_id = 1 and month(transaction_time) = 1

/* 1.2 Based on your previous query, let’s calculate the Success Rate of each transaction_type. The desired outcome has the following columns: 
Transaction type
Number of transaction
Number of successful transaction
Success rate = Number of successful transaction/ Number of transaction */

WITH temp AS(
    SELECT t20.*
            ,transaction_type
            ,status_description
            ,COUNT(transaction_time) OVER(PARTITION BY transaction_type) AS nb_trans
    FROM fact_transaction_2020 t20 
    JOIN dim_scenario sce ON t20.scenario_id = sce.scenario_id
    JOIN dim_status sta ON t20.status_id = sta.status_id
    WHERE month(transaction_time) = 1
)
SELECT DISTINCT transaction_type
    ,nb_trans
    ,COUNT(transaction_time) OVER(PARTITION BY transaction_type) AS nb_success_trans
    ,FORMAT(1.0*COUNT(transaction_time) OVER(PARTITION BY transaction_type)/ nb_trans,'p') AS success_rate
FROM temp
WHERE temp.status_id = 1 
ORDER BY nb_trans DESC

-- 2.1 

WITH temp AS (
    SELECT fact_19.*
    FROM fact_transaction_2019 fact_19 
    JOIN dim_scenario sce ON fact_19.scenario_id = sce.scenario_id
    WHERE category = 'Billing' AND status_id = 1
UNION
    SELECT fact_20.*
    FROM fact_transaction_2020 fact_20 
    JOIN dim_scenario sce ON fact_20.scenario_id = sce.scenario_id
    WHERE category = 'Billing' AND status_id = 1 
)

SELECT customer_id
    , DATEDIFF(day, MAX(transaction_time), '2020-12-31') AS recency 
    , COUNT(transaction_time) AS frequency
    , SUM(charged_amount) AS monetary 
FROM temp
GROUP BY customer_id

-- 2.2
WITH fact_table AS (
    SELECT fact_19.*
    FROM fact_transaction_2019 fact_19 
    JOIN dim_scenario sce ON fact_19.scenario_id = sce.scenario_id
    WHERE category = 'Billing' AND status_id = 1
UNION
    SELECT fact_20.*
    FROM fact_transaction_2020 fact_20 
    JOIN dim_scenario sce ON fact_20.scenario_id = sce.scenario_id
    WHERE category = 'Billing' AND status_id = 1 
)
, rfm_metric AS (
SELECT customer_id
    , DATEDIFF(day, MAX(transaction_time), '2020-12-31') AS recency 
    , COUNT(transaction_time) AS frequency
    , SUM(charged_amount) AS monetary 
FROM fact_table
GROUP BY customer_id
)
, rfm_tier AS (
SELECT *
    , CASE WHEN  PERCENT_RANK() OVER ( ORDER BY recency ASC ) > 0.75 THEN 4
    WHEN PERCENT_RANK() OVER ( ORDER BY recency ASC ) > 0.5 THEN 3
    WHEN PERCENT_RANK() OVER ( ORDER BY recency ASC ) > 0.25 THEN 2
    ELSE 1 END AS r_tier
    , CASE WHEN  PERCENT_RANK() OVER ( ORDER BY frequency DESC ) > 0.75 THEN 4
    WHEN PERCENT_RANK() OVER ( ORDER BY frequency DESC ) > 0.5 THEN 3
    WHEN PERCENT_RANK() OVER ( ORDER BY frequency DESC ) > 0.25 THEN 2
    ELSE 1 END AS f_tier 
    , CASE WHEN  PERCENT_RANK() OVER ( ORDER BY monetary DESC ) > 0.75 THEN 4
    WHEN PERCENT_RANK() OVER ( ORDER BY monetary DESC ) > 0.5 THEN 3
    WHEN PERCENT_RANK() OVER ( ORDER BY monetary DESC ) > 0.25 THEN 2
    ELSE 1 END AS m_tier 
FROM rfm_metric
)

, segment_table AS (
SELECT *
    , CASE 
        WHEN CONCAT(r_tier, f_tier, m_tier)  =  111 THEN 'Best Customers'
        WHEN CONCAT(r_tier, f_tier, m_tier) LIKE '[3-4][3-4][1-4]' THEN 'Lost Bad Customer'
        WHEN CONCAT(r_tier, f_tier, m_tier) LIKE '[3-4]2[1-4]' THEN 'Lost Customers'
        WHEN CONCAT(r_tier, f_tier, m_tier) LIKE  '21[1-4]' THEN 'Almost Lost'
        WHEN CONCAT(r_tier, f_tier, m_tier) LIKE  '11[2-4]' THEN 'Loyal Customers'
        WHEN CONCAT(r_tier, f_tier, m_tier) LIKE  '[1-2][1-3]1' THEN 'Big Spenders'
        WHEN CONCAT(r_tier, f_tier, m_tier) LIKE  '[1-2]4[1-4]' THEN 'New Customers'
        WHEN CONCAT(r_tier, f_tier, m_tier) LIKE  '[3-4]1[1-4]' THEN 'Hibernating'
        WHEN CONCAT(r_tier, f_tier, m_tier) LIKE  '[1-2][2-3][2-4]' THEN 'Potential Loyalists'
    ELSE 'unknown'
    END AS segment
FROM rfm_tier)
SELECT
    segment
    , COUNT( customer_id) AS number_users 
    , SUM( COUNT( customer_id)) OVER() AS total_users
    , FORMAT( 1.0*COUNT( customer_id) / SUM( COUNT( customer_id)) OVER(), 'p') AS pct
FROM segment_table
GROUP BY segment
ORDER BY number_users DESC;



