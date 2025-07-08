SELECT * FROM vehicle_sales;

-- Customers who purchased the same vihecle models more than once in the same year
SELECT customer_id, Model, YEAR(purchase_date)
FROM vehicle_sales
GROUP BY customer_id, Model, YEAR(purchase_date)
HAVING count(*) > 1 ;

-- Identifying vehicles not serviced in the last 12 months
SELECT * FROM vehicle_master;
SELECT * FROM service_logs;

WITH not_serviced_12_Months AS (
SELECT VM.vehicle_id,
       Max(service_date) AS last_service_date	 	
FROM vehicle_master VM
LEFT JOIN service_logs SL
	ON VM.vehicle_id = SL.vehicle_id
GROUP BY VM.vehicle_id,registration_date
)
SELECT *
FROM not_serviced_12_Months
WHERE last_service_date IS NULL OR last_service_date <  DATE('2025/05/21')  - INTERVAL 12 MONTH;

-- GET TOP 3 DEALERS PER REGION BASED ON PROFIT ONLY FOR Q1
SELECT * FROM dealer_revenue;

WITH RANKING AS (
SELECT dealer_id,region,
        (revenue-cost) AS profit,
       RANK() OVER(PARTITION BY REGION ORDER BY (revenue-cost) DESC) AS RANK_
FROM dealer_revenue 
WHERE QUARTER(MONTH) = 1 
 )
SELECT dealer_id,region,
	profit
FROM RANKING  
WHERE RANK_ <= 3 ;


-- Calculate the month-over-month % growth in service appointments in 2024. 
SELECT * FROM service_appointments;
With CTE AS (
			SELECT 
				   monthname(service_date) Monthname_ ,
                   COUNT(*) AS total_appointments
			FROM service_appointments
            Where service_date BETWEEN  '2024/01/01' AND '2024/12/31'
            Group by 1
),
growth_calc AS (
		SELECT Monthname_,total_appointments,
        LAG(total_appointments,1,0) OVER(order by monthname_) AS prev_month_appointments
        From CTE )
        
SELECT Monthname_,total_appointments, prev_month_appointments,
	  ROUND(total_appointments - prev_month_appointments/prev_month_appointments,0)* 100 AS Growth
FROM growth_Calc
Order by Monthname_;


-- Flag older records where customer email and phone are duplicated. 

SELECT * FROM ford_questions.customer_contacts;

WITH FLAGING AS 
(	
SELECT customer_id,email,phone_number,last_updated,
       ROW_NUMBER() OVER(PARTITION BY email,phone_number ORDER BY last_updated) AS SAME_INFO_CHECKING
FROM customer_contacts 
)

SELECT customer_id,email,phone_number,last_updated,
   CASE 
		WHEN SAME_INFO_CHECKING > 1 THEN 'DUPLICATE OLDER'
	ELSE
		'LATEST'
        END AS 'status'
FROM FLAGING;

-- Find customers who bought both Ford Mustang and Ford Figo.

SELECT * FROM sales_data;

SELECT customer_id 
FROM sales_data 
WHERE model IN ('Ford Mustang', 'Ford Figo') 
GROUP BY customer_id 
HAVING COUNT(DISTINCT model) = 2; 

-- . Get the latest service record for each vehicle along with cost.
SELECT * from service_records;

With latest_service AS (
SELECT vehicle_id, service_date, service_cost,
ROW_NUMBER() OVER(partition by vehicle_id order by service_date DESC) AS latest_service_date
FROM service_records 
)

SELECT vehicle_id, service_date, service_cost
FROM latest_service
Where latest_service_date = 1