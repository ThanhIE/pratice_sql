/* 1. Task 1: Retrieve an overview report of payment types
1.1. Paytm has a wide variety of transaction types in its business. Your manager wants to know the
contribution (by percentage) of each transaction type to total transactions. Retrieve a report that
includes the following information: transaction type, number of transaction and proportion of each
type in total. These transactions must meet the following conditions:
Were created in 2019
Were paid successfully
Show only the results of the top 5 types with the highest percentage of the total. */


SELECT 
TOP 5 transaction_type
, COUNT(transaction_id) as number_trans
, ( SELECT count(transaction_id) from fact_transaction_2019 where status_id = 1) as total_trans
, ROUND((COUNT(transaction_id)*100.0/( SELECT count(transaction_id) from fact_transaction_2019 where status_id = 1)), 2) as pct 
FROM fact_transaction_2019 as t2019
LEFT JOIN dim_scenario as sce
ON sce.scenario_id = t2019.scenario_id
WHERE 
t2019.status_id = 1
GROUP BY transaction_type
ORDER BY number_trans DESC

-- Anh Hiếu chỉ em cách format kết quả phần trăm giống như kết quả mẫu với ạ ?

/* Retrieve a more detailed report with following information: transaction type, category, number of transaction and proportion of each category in the total of that transaction type. These transactions must meet the following conditions: 
Were created in 2019 
Were paid successfully */

WITH temp as 
( SELECT
    transaction_type
    ,CASE WHEN Count(transaction_type) != 0 THEN Count(category)
    ELSE Null END as number_trans_type
    FROM fact_transaction_2019 as t2019
    JOIN dim_scenario as sce
    ON sce.scenario_id = t2019.scenario_id
    WHERE status_id = 1
    GROUP BY transaction_type)
,
temp1(transaction_type, category, number_trans_category) as 
(SELECT 
sce.transaction_type
, category
, COUNT(transaction_id) as number_trans_category
FROM fact_transaction_2019 as t2019
LEFT JOIN dim_scenario as sce
ON sce.scenario_id = t2019.scenario_id
WHERE 
t2019.status_id = 1
GROUP BY sce.transaction_type, category)
SELECT 
temp1.transaction_type
, category
, number_trans_category
, number_trans_type
, ROUND((number_trans_category*100.0/number_trans_type), 2) as pct 
FROM temp
FULL OUTER JOIN temp1
ON temp.transaction_type = temp1.transaction_type
ORDER BY transaction_type  ASC, pct DESC






-- ORDER BY number_trans DESC








/* Task 2: Retrieve an overview report of customer’s payment behaviors
Paytm has acquired a lot of customers. Retrieve a report that includes the following information: the number of transactions,
 the number of payment scenarios, the number of payment category and the total of charged amount of each customer.
Were created in 2019
Had status description is successful
Had transaction type is payment
Only show Top 10 highest customers by the number of transactions */

SELECT 
TOP 10 customer_id
, COUNT(transaction_id) as number_trans
, COUNT(distinct t2019.scenario_id) as number_scenarios
, count(distinct category) as number_categories
, SUM(charged_amount) as total_amount
FROM fact_transaction_2019 as t2019
LEFT JOIN dim_scenario as sce
ON sce.scenario_id = t2019.scenario_id
WHERE 
t2019.status_id = 1 
AND sce.transaction_type = 'Payment'
GROUP BY customer_id
ORDER BY number_trans DESC

/* After looking at the above metrics of customer’s payment behaviors, we want to analyze the distribution of each metric. Before calculating and plotting the distribution to check the frequency of values in each metric, we need to group the observations into range.
 How can we group the observations in the most logical way? Binning is useful to help us deal with problem. To use binning method, we need to determine how many bins for each distribution of each field.
Retrieve a report that includes the following columns: metric, minimum value, maximum value and average value of these metrics:
The total charged amount
The number of transactions
The number of payment scenarios
The number of payment categories */

WITH temp as 
(SELECT 
customer_id
, COUNT(transaction_id) as number_trans
, COUNT(distinct t2019.scenario_id) as number_scenarios
, count(distinct category) as number_categories
, SUM(charged_amount) as total_amount
FROM fact_transaction_2019 as t2019
LEFT JOIN dim_scenario as sce
ON sce.scenario_id = t2019.scenario_id
WHERE 
t2019.status_id = 1 
AND sce.transaction_type = 'Payment'
GROUP BY customer_id
)
SELECT
'The total charged amount' as metric
, min(total_amount) as min_value
, max(total_amount) as max_value
, avg(cast(total_amount as float)) as avg_value
FROM temp
UNION
SELECT
'The number of transactions' as metric
, min(number_trans) as min_value
, max(number_trans) as max_value
, floor(avg(cast(number_trans as float))) as avg_value
FROM temp
UNION
SELECT
'The number of payment scenarios' as metric
, min(number_scenarios) as min_value
, max(number_scenarios) as max_value
, floor(avg(cast(number_scenarios as float))) as avg_value
FROM temp
UNION
SELECT
'The number of payment categories' as metric
, min(number_categories) as min_value
, max(number_categories) as max_value
, floor(avg(cast(number_categories as float))) as avg_value
FROM temp

/* 2.2.2 Bin the total charged amount and number of transactions then calculate the frequency of each field in each metric
Metric 1: The total charged amount */

    WITH tem1 as 
    (SELECT
    customer_id
    , CASE WHEN SUM(charged_amount) >= 0 AND SUM(charged_amount) < 1000000 THEN '0-01M'
                WHEN SUM(charged_amount) >= 1000000 AND SUM(charged_amount) < 2000000 THEN '01M-02M'
                WHEN SUM(charged_amount) >= 2000000 AND SUM(charged_amount) < 3000000 THEN '02M-03M'
                WHEN SUM(charged_amount) >= 3000000 AND SUM(charged_amount) < 4000000 THEN '03M-04M'
                WHEN SUM(charged_amount) >= 4000000 AND SUM(charged_amount) < 5000000 THEN '04M-05M'
                WHEN SUM(charged_amount) >= 5000000 AND SUM(charged_amount) < 6000000 THEN '05M-06M'
                WHEN SUM(charged_amount) >= 6000000 AND SUM(charged_amount) < 7000000 THEN '06M-07M'
                WHEN SUM(charged_amount) >= 7000000 AND SUM(charged_amount) < 8000000 THEN '07M-08M'
                WHEN SUM(charged_amount) >= 8000000 AND SUM(charged_amount) < 9000000 THEN '08M-09M'
                WHEN SUM(charged_amount) >= 9000000 AND SUM(charged_amount) < 10000000 THEN '09M-10M'
                ELSE '> 10M' END as charged_amount_range
    from fact_transaction_2019 as t2019
    LEFT JOIN dim_scenario as sce
    ON sce.scenario_id = t2019.scenario_id
    WHERE 
    t2019.status_id = 1 
    AND sce.transaction_type = 'Payment'
    GROUP BY customer_id)
    SELECT 
    charged_amount_range
    , COUNT(customer_id) as number_customers
    FROM tem1 
    GROUP BY charged_amount_range
    ORDER BY charged_amount_range

-- Metric 2: The number of transactions

    WITH tem1 as 
    (SELECT
    customer_id
    , CASE WHEN COUNT(transaction_id) >= 0 AND COUNT(transaction_id) < 10 THEN '[0-10]'
                WHEN COUNT(transaction_id) >= 10 AND COUNT(transaction_id) < 20 THEN '[10-20]'
                WHEN COUNT(transaction_id) >= 20 AND COUNT(transaction_id) < 30 THEN '[20-30]'
                WHEN COUNT(transaction_id) >= 30 AND COUNT(transaction_id) < 40 THEN '[30-40]'
                WHEN COUNT(transaction_id) >= 40 AND COUNT(transaction_id) < 50 THEN '[40-50]'
                WHEN COUNT(transaction_id) >= 50 AND COUNT(transaction_id) < 60 THEN '[50-60]'
                WHEN COUNT(transaction_id) >= 60 AND COUNT(transaction_id) < 70 THEN '[60-70]'
                WHEN COUNT(transaction_id) >= 70 AND COUNT(transaction_id) < 80 THEN '[70-80]'
                WHEN COUNT(transaction_id) >= 80 AND COUNT(transaction_id) < 90 THEN '[80-90]'
                WHEN COUNT(transaction_id) >= 90 AND COUNT(transaction_id) < 100 THEN '[90-100]'
                ELSE '[more than 100]' END as number_trans_range
    from fact_transaction_2019 as t2019
    LEFT JOIN dim_scenario as sce
    ON sce.scenario_id = t2019.scenario_id
    WHERE 
    t2019.status_id = 1 
    AND sce.transaction_type = 'Payment'
    GROUP BY customer_id)
    SELECT 
    number_trans_range
    , COUNT(customer_id) as number_customers
    FROM tem1 
    GROUP BY number_trans_range
    ORDER BY number_trans_range

-- Metric 3: The number of payment categories

WITH temp as 
(SELECT 
customer_id
, COUNT(transaction_id) as number_trans
, COUNT(distinct t2019.scenario_id) as number_scenarios
, count(distinct category) as number_categories
, SUM(charged_amount) as total_amount
FROM fact_transaction_2019 as t2019
LEFT JOIN dim_scenario as sce
ON sce.scenario_id = t2019.scenario_id
WHERE 
t2019.status_id = 1 
AND sce.transaction_type = 'Payment'
GROUP BY customer_id
)
SELECT 
number_categories
, count(customer_id) as number_customers
FROM temp
GROUP BY number_categories

-- Metric 4: The number of payment scenarios

WITH temp as 
(SELECT 
customer_id
, COUNT(transaction_id) as number_trans
, COUNT(distinct t2019.scenario_id) as number_scenarios
, count(distinct category) as number_categories
, SUM(charged_amount) as total_amount
FROM fact_transaction_2019 as t2019
LEFT JOIN dim_scenario as sce
ON sce.scenario_id = t2019.scenario_id
WHERE 
t2019.status_id = 1 
AND sce.transaction_type = 'Payment'
GROUP BY customer_id
)
SELECT 
number_scenarios
, count(customer_id) as number_customers
FROM temp
GROUP BY number_scenarios