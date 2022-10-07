--PART 2: Use database PayTM
 
/* Task 1: Retrieve reports on transaction scenarios
1.1 Retrieve a report that includes the following information: customer_id, transaction_id,
scenario_id, transaction_type, sub_category, category. These transactions must meet the
following conditions:
 Were created in Jan 2019
 Transaction type is not payment */

SELECT
t2019.transaction_id 
, t2019.customer_id
, t2019.scenario_id
, transaction_type
, sub_category
, category
FROM fact_transaction_2019 as t2019
JOIN dim_scenario as sce 
on sce.scenario_id = t2019.scenario_id
WHERE sce.transaction_type not like 'Payment'
AND MONTH(transaction_time) = 1

/*1.2 Retrieve a report that includes the following information: customer_id, transaction_id,
scenario_id, transaction_type, category, payment_method. These transactions must meet the
following conditions:
 Were created from Jan to June 2019
 Had category type is shopping
 Were paid by Bank account */

SELECT
t2019.transaction_id 
, t2019.customer_id
, t2019.scenario_id
, transaction_type
, category
, payment_method
, transaction_time
FROM fact_transaction_2019 as t2019
JOIN dim_scenario as sce 
ON sce.scenario_id = t2019.scenario_id
JOIN dim_payment_channel as pay
ON t2019.payment_channel_id = pay.payment_channel_id
WHERE 
(MONTH(transaction_time) BETWEEN 1 AND 6)
AND sce.category like 'Shopping'
AND pay.payment_method like 'Bank account'

/* 1.3 Retrieve a report that includes the following information: customer_id, transaction_id,
scenario_id, payment_method and payment_platform. These transactions must meet the
following conditions:
 Were created in Jan 2019 and Jan 2020
 Had payment platform is android */

SELECT
t2019.transaction_id 
, t2019.customer_id
, t2019.scenario_id
, payment_method
, payment_platform
, transaction_time
FROM fact_transaction_2019 as t2019
JOIN dim_payment_channel as pay
ON t2019.payment_channel_id = pay.payment_channel_id
JOIN dim_platform as pla 
ON t2019.platform_id = pla.platform_id
WHERE
MONTH(transaction_time) = 1
AND pla.payment_platform like 'android'
UNION ALL
 SELECT
t2020.transaction_id 
, t2020.customer_id
, t2020.scenario_id
, payment_method
, payment_platform
, transaction_time
FROM fact_transaction_2020 as t2020
JOIN dim_payment_channel as pay
ON t2020.payment_channel_id = pay.payment_channel_id
JOIN dim_platform as pla 
ON t2020.platform_id = pla.platform_id
WHERE
MONTH(transaction_time) = 1
AND pla.payment_platform like 'android'

/* 1.4 Retrieve a report that includes the following information: customer_id, transaction_id,
scenario_id, payment_method and payment_platform. These transactions must meet the
following conditions:
 Include all transactions of the customer group created in January 2019 (Group A) and
additional transactions of this customers (Group A) continue to make transactions in
January 2020.
 Payment platform is iOS */

SELECT
t2019.transaction_id 
, t2019.customer_id
, t2019.scenario_id
, payment_method
, payment_platform
, transaction_time
FROM fact_transaction_2019 as t2019
JOIN dim_payment_channel as pay
ON t2019.payment_channel_id = pay.payment_channel_id
JOIN dim_platform as pla 
ON t2019.platform_id = pla.platform_id
WHERE
MONTH(transaction_time) = 1
AND pla.payment_platform like 'ios'

UNION

SELECT
t2020.transaction_id 
, t2020.customer_id
, t2020.scenario_id
, payment_method
, payment_platform
, transaction_time
FROM fact_transaction_2020 as t2020
JOIN dim_payment_channel as pay
ON t2020.payment_channel_id = pay.payment_channel_id
JOIN dim_platform as pla 
ON t2020.platform_id = pla.platform_id
WHERE
MONTH(t2020.transaction_time) = 1
AND pla.payment_platform like 'ios'
AND t2020.customer_id in 
(SELECT t2019.customer_id 
from fact_transaction_2019 as t2019 
JOIN dim_payment_channel as pay
ON t2019.payment_channel_id = pay.payment_channel_id
JOIN dim_platform as pla 
ON t2019.platform_id = pla.platform_id
WHERE
MONTH(transaction_time) = 1
AND pla.payment_platform like 'ios')
order by customer_id