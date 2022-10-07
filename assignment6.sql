/* Simple trend
Task: You need to analyze the trend of payment transactions of Billing category from 2019 to 2020. First, let’s show the trend of the number of successful transactions by month.*/


SELECT DISTINCT YEAR(transaction_time) as year 
        ,MONTH(transaction_time)  as month 
        ,CONCAT(YEAR(transaction_time),MONTH(transaction_time)) as time_calendar
        ,COUNT(transaction_id) OVER(PARTITION BY MONTH(transaction_time) ORDER BY MONTH(transaction_time)) AS number_trans
FROM fact_transaction_2019 as t2019
LEFT JOIN dim_scenario as sce
ON t2019.scenario_id = sce.scenario_id 
WHERE  t2019.status_id = 1 and category = 'Billing'
UNION
SELECT DISTINCT YEAR(transaction_time) as year 
        ,MONTH(transaction_time) as month 
        ,CONCAT(YEAR(transaction_time),MONTH(transaction_time)) as time_calendar
        ,COUNT(transaction_id) OVER(PARTITION BY MONTH(transaction_time) ORDER BY MONTH(transaction_time)) AS number_trans
FROM fact_transaction_2020 as t2020
LEFT JOIN dim_scenario as sce
ON t2020.scenario_id = sce.scenario_id 
WHERE  t2020.status_id = 1 and category = 'Billing'

/* 1.2. Comparing Component
Task: You know that there are many sub-categories of Billing group. After reviewing the above result, you should break down the trend into each sub-categories.*/

SELECT  YEAR(transaction_time) as year 
        ,MONTH(transaction_time) as month 
        ,sub_category
        ,COUNT (transaction_id) as number_trans
FROM fact_transaction_2019 as t2019
LEFT JOIN dim_scenario as sce
ON t2019.scenario_id = sce.scenario_id 
WHERE  t2019.status_id = 1 and category = 'Billing'
GROUP BY YEAR(transaction_time)
        ,MONTH(transaction_time) 
        ,sub_category
UNION
SELECT  YEAR(transaction_time) as year 
        ,MONTH(transaction_time) as month 
        ,sub_category
        ,COUNT (transaction_id) as number_trans
FROM fact_transaction_2020 as t2020
LEFT JOIN dim_scenario as sce
ON t2020.scenario_id = sce.scenario_id 
WHERE  t2020.status_id = 1 and category = 'Billing'
GROUP BY YEAR(transaction_time)
        ,MONTH(transaction_time) 
        ,sub_category
ORDER BY year, month 

/* Then modify the result as the following table: Only select the sub-categories belong to list (Electricity, Internet and Water)
*/
WITH temp AS
(
        SELECT t2019.transaction_id
                ,sub_category
                ,YEAR(transaction_time) as year
                ,MONTH(transaction_time) as month
        FROM fact_transaction_2019 as t2019
        LEFT JOIN dim_scenario as sce
        ON t2019.scenario_id = sce.scenario_id 
        WHERE  t2019.status_id = 1 and sub_category in ('Electricity','Internet','Water')
        UNION
        SELECT t2020.transaction_id
                ,sub_category
                ,YEAR(transaction_time) as year
                ,MONTH(transaction_time) as month
        FROM fact_transaction_2020 as t2020
        LEFT JOIN dim_scenario as sce
        ON t2020.scenario_id = sce.scenario_id 
        WHERE  t2020.status_id = 1 and sub_category in ('Electricity','Internet','Water')
),
temp1 AS
        (SELECT DISTINCT year 
                ,month
                ,COUNT(transaction_id) OVER (PARTITION BY year, month) as electricity_trans
        FROM temp
        WHERE sub_category ='Electricity'),
temp2 AS
        (SELECT DISTINCT year 
                ,month 
                ,COUNT(transaction_id) OVER (PARTITION BY year, month) as internet_trans
        FROM temp
        WHERE sub_category ='Internet'),
temp3 AS
        (SELECT DISTINCT year 
                ,month 
                ,COUNT(transaction_id) OVER (PARTITION BY year, month) AS water_trans
        FROM temp
        WHERE sub_category ='Water')
SELECT temp1.year 
        ,temp1.month
        ,electricity_trans 
        ,internet_trans
        ,water_trans       
FROM temp1
LEFT JOIN temp2
ON temp1.year = temp2.year and temp1.month = temp2.month
LEFT JOIN temp3
ON temp1.year = temp3.year and temp1.month = temp3.month 

/* 1.3 Percent of Total Calculations: When working with time series data that has multiple parts or attributes that constitute a whole, it’s often useful to analyze each part’s contribution to the whole and whether that has changed over time. Unless the data already contains a time series of the total values, we’ll need to calculate the overall total in order to calculate the percent of total for each row. 
*/
WITH temp AS
(
        SELECT t2019.transaction_id
                ,sub_category
                ,YEAR(transaction_time) as year
                ,MONTH(transaction_time) as month
                ,COUNT(*)OVER(PARTITION BY MONTH(transaction_time)) as total_trans
        FROM fact_transaction_2019 as t2019
        LEFT JOIN dim_scenario as sce
        ON t2019.scenario_id = sce.scenario_id 
        WHERE  t2019.status_id = 1 and sub_category in ('Electricity','Internet','Water')
        UNION
        SELECT t2020.transaction_id
                ,sub_category
                ,YEAR(transaction_time) as year
                ,MONTH(transaction_time) as month
                ,COUNT(*)OVER(PARTITION BY MONTH(transaction_time)) as total_trans
        FROM fact_transaction_2020 as t2020
        LEFT JOIN dim_scenario as sce
        ON t2020.scenario_id = sce.scenario_id 
        WHERE  t2020.status_id = 1 and sub_category in ('Electricity','Internet','Water')
),
temp1 AS
        (SELECT DISTINCT year 
                ,month
                ,COUNT(transaction_id) OVER (PARTITION BY year, month) as electricity_trans
                ,total_trans
        FROM temp
        WHERE sub_category ='Electricity'),
temp2 AS
        (SELECT DISTINCT year 
                ,month 
                ,COUNT(transaction_id) OVER (PARTITION BY year, month) as internet_trans
                ,total_trans
        FROM temp
        WHERE sub_category ='Internet'),
temp3 AS
        (SELECT DISTINCT year 
                ,month 
                ,COUNT(transaction_id) OVER (PARTITION BY year, month) AS water_trans
                ,total_trans
        FROM temp
        WHERE sub_category ='Water')
SELECT temp1.year 
        , temp1.month
        , temp1.electricity_trans 
        , temp2.internet_trans
        , temp3.water_trans
        ,FORMAT(1.0*electricity_trans/temp1.total_trans,'p')  AS elect_pct
        ,FORMAT(1.0*internet_trans/temp1.total_trans,'p')  AS internet_pct
        ,FORMAT(1.0*water_trans/temp1.total_trans,'p')  AS internet_pct
FROM temp1
LEFT JOIN temp2
ON temp1.year = temp2.year and temp1.month = temp2.month
LEFT JOIN temp3
ON temp1.year = temp3.year and temp1.month = temp3.month 
-- LEFT JOIN temp 
-- ON temp1.year = temp.year and temp1.month = temp.month


/* 1.4 Indexing to See Percent Change over Time: Indexing data is a way to understand the changes in a time series relative to a base period (starting point). Indices are widely used in economics as well as business settings.
Task: Select only these sub-categories in the list (Electricity, Internet and Water), you need to calculate the number of successful paying customers for each month (from 2019 to 2020). Then find the percentage change from the first month (Jan 2019) for each subsequent month.*/

WITH temp AS
(
        SELECT  YEAR(transaction_time) as year
                ,MONTH(transaction_time) as month
                ,CONCAT(YEAR(transaction_time),MONTH(transaction_time)) AS calendar_time
                ,COUNT(DISTINCT customer_id) as number_cus
        FROM fact_transaction_2019 as t2019
        LEFT JOIN dim_scenario sce
        ON t2019.scenario_id = sce.scenario_id 
        WHERE  t2019.status_id = 1 and sub_category in ('Electricity','Internet','Water')
        GROUP BY YEAR(transaction_time)
                ,MONTH(transaction_time)
UNION
        SELECT  YEAR(transaction_time) as year
                ,MONTH(transaction_time) as month
                ,CONCAT(YEAR(transaction_time),MONTH(transaction_time)) AS calendar_time
                ,COUNT(DISTINCT customer_id) as number_cus
        FROM fact_transaction_2020 as t2020
        LEFT JOIN dim_scenario sce
        ON t2020.scenario_id = sce.scenario_id 
        WHERE t2020.status_id = 1 and sub_category in ('Electricity','Internet','Water')
         GROUP BY YEAR(transaction_time)
                ,MONTH(transaction_time)
)
SELECT month 
        ,year
        ,number_cus
        ,(select number_cus FROM temp WHERE calendar_time = '20191') as starting_point
        ,FORMAT(
                1.0*(number_cus-(select number_cus FROM temp WHERE calendar_time = '20191'))
                /(select number_cus FROM temp WHERE calendar_time = '20191'),'p') 
        AS diff_pct
FROM temp


/* 2.1 Calculating Rolling Time Windows
Task: Select only these sub-categories in the list (Electricity, Internet and Water), you need to calculate the number of successful paying customers for each week number from 2019 to 2020). Then get rolling annual paying users of this group. */
WITH temp AS 
(
        SELECT YEAR (transaction_time) as year 
                ,DATEPART(week,transaction_time) AS week_calendar
                ,COUNT(DISTINCT customer_id) AS number_customers
        FROM fact_transaction_2019 t2019 
        JOIN dim_scenario sce 
        ON t2019.scenario_id = sce.scenario_id
        WHERE sub_category in ('Electricity','Internet','Water') AND status_id = 1
        GROUP BY YEAR (transaction_time)
                ,DATEPART(week,transaction_time)
UNION
        SELECT YEAR (transaction_time) as year 
                ,DATEPART(week,transaction_time) AS week_calendar
                ,COUNT(DISTINCT customer_id) AS number_customers
        FROM fact_transaction_2020 t2020 
        JOIN dim_scenario sce 
        ON t2020.scenario_id = sce.scenario_id
        WHERE sub_category in ('Electricity','Internet','Water') AND status_id = 1
        GROUP BY YEAR (transaction_time)
                ,DATEPART(week,transaction_time)
)
SELECT *
    ,SUM(number_customers) OVER ( ORDER BY year, week_calendar ASC ) AS rolling_user 
FROM temp

2.2
WITH temp AS 
(
        SELECT YEAR (transaction_time) as year 
                ,DATEPART(week,transaction_time) AS week_calendar
                ,COUNT(DISTINCT customer_id) AS number_customers
        FROM fact_transaction_2019 t2019 
        JOIN dim_scenario sce 
        ON t2019.scenario_id = sce.scenario_id
        WHERE sub_category in ('Electricity','Internet','Water') AND status_id = 1
        GROUP BY YEAR (transaction_time)
                ,DATEPART(week,transaction_time)
UNION
        SELECT YEAR (transaction_time) as year 
                ,DATEPART(week,transaction_time) AS week_calendar
                ,COUNT(DISTINCT customer_id) AS number_customers
        FROM fact_transaction_2020 t2020 
        JOIN dim_scenario sce 
        ON t2020.scenario_id = sce.scenario_id
        WHERE sub_category in ('Electricity','Internet','Water') AND status_id = 1
        GROUP BY YEAR (transaction_time)
                ,DATEPART(week,transaction_time)
)
SELECT *
        ,AVG(number_customers) OVER (ORDER BY year,week_calendar ROWS BETWEEN 3 PRECEDING AND 0 FOLLOWING) AS avg_last_4_weeks
FROM temp

