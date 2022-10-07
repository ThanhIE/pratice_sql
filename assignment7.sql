/* Task1: 
A
As you know that 'Telco Card' is the most product in the Telco group (accounting for more
than 99% of the total). You want to evaluate the quality of user acquisition in Jan 2019 by the
retention metric. First, you need to know how many users are retained in each subsequent
month from the first month (Jan 2019) they pay the successful transaction (only get data of
2019). */


WITH telco_table as (
SELECT t2019.*
, category
, MONTH (transaction_time) as month
FROM fact_transaction_2019 as t2019
LEFT JOIN dim_scenario as sce
ON t2019.scenario_id = sce.scenario_id
WHERE category = 'Telco' and sub_category = 'Telco Card' and status_id = 1
)
SELECT subsequent_month = month -1
, COUNT (DISTINCT customer_id) as retained_users
FROM telco_table
WHERE customer_id IN (SELECT DISTINCT customer_id

FROM telco_table
WHERE month =1)

GROUP BY month
ORDER BY month

/*B. You realize that the number of retained customers has decreased over time. Let’s calculate
retention = number of retained customers / total users of the first month.*/
WITH telco_table as (
SELECT t2019.*
, category
, MONTH (transaction_time) as month
FROM fact_transaction_2019 as t2019
LEFT JOIN dim_scenario as sce
ON t2019.scenario_id = sce.scenario_id
WHERE category = 'Telco' and sub_category = 'Telco Card' and status_id = 1
)
SELECT subsequent_month = month -1
, COUNT (DISTINCT customer_id) as retained_users
, (SELECT COUNT(DISTINCT customer_id) FROM telco_table WHERE month = 1) as original_users
, FORMAT(1.0*COUNT (DISTINCT customer_id)/(SELECT COUNT(DISTINCT customer_id) FROM telco_table WHERE month = 1), 'p') as pct_retained
FROM telco_table
WHERE customer_id IN (SELECT DISTINCT customer_id

FROM telco_table
WHERE month =1)

GROUP BY month
ORDER BY month

/* 1.2. Cohorts Derived from the Time Series Itself
Task: Expend your previous query to calculate retention for multi attributes from the acquisition
month (from Jan to December). */



2.1

WITH temp AS (
    SELECT customer_id
            ,transaction_time
            ,charged_amount
    FROM fact_transaction_2019 t2019
    JOIN dim_scenario AS sce 
    ON t2019.scenario_id = sce.scenario_id
    WHERE status_id = 1 AND sub_category ='Telco Card'
    UNION 
    SELECT customer_id
            ,transaction_time
            ,charged_amount
    FROM fact_transaction_2020 t2020
    JOIN dim_scenario AS sce ON t2020.scenario_id = sce.scenario_id
    WHERE status_id = 1 AND sub_category ='Telco Card' 
    )
SELECT customer_id
        ,DATEDIFF(day,max(transaction_time),'2020-12-31') as Recency
        ,DATEDIFF(day,min(transaction_time),max(transaction_time))/COUNT(transaction_time) as Frequency
        ,sum(charged_amount) as Monetary
FROM temp
GROUP BY customer_id
ORDER BY Monetary


