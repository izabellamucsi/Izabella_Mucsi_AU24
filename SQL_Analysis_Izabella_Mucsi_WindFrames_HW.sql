/*Task 1. Create a query for analyzing the annual sales data for the years 1999 to 2001, focusing on different sales channels and regions: 'Americas,' 'Asia,' and 'Europe.' 
Soltion: The task was broken down into four ctes. The first one, yearly_sales calculates the sales data by region, year, and channel for every time period. 
In the next step, the total_sales CTE calculates the total annual sales for each region, in order to find the percentage contribution of each sales channel which will be used to calculate the percentage of sales for each channel within a region and year.
The third percentage_sales cte compares the sales of each channel relative to the total sales for that region and year and calculates the percentage ratio. 
In the next step I used the LAG function to retrieve the sales percentages for the previous year. The reason for using the LAG function and calculating the sales percentages in two different step is to make sure that the LAG operates on already calculated percentages.
Finally, the query generates the report by calculating the difference between the sales by channels percentage and the previous period percentage called %difference to show the changes in the percentage contribution of sales channels over time.
Filtering by the year between 1999 and 2001 is placed in the final query to make sure that all the historical data will be available for the LAG function. */

WITH yearly_sales AS (
SELECT
c3.country_region,
EXTRACT(YEAR FROM s.time_id) AS calendar_year,
c2.channel_desc,
SUM(s.amount_sold) AS amount_sold
FROM sh.sales s
INNER JOIN sh.customers c ON s.cust_id = c.cust_id
INNER JOIN sh.channels c2 ON s.channel_id = c2.channel_id
INNER JOIN sh.countries c3 ON c3.country_id = c.country_id
WHERE lower(c3.country_region) IN ('americas', 'asia', 'europe') 
GROUP BY c3.country_region, EXTRACT(YEAR FROM s.time_id), c2.channel_desc),
	total_sales AS (
    SELECT
    country_region,
    calendar_year,
    SUM(amount_sold) AS total_sales
    FROM yearly_sales ys
    GROUP BY country_region, calendar_year),
	percentage_sales AS (
    SELECT
    ys.country_region,
    ys.calendar_year,
    ys.channel_desc,
    ys.amount_sold,
    ROUND(ys.amount_sold * 100.0 / t.total_sales, 2) AS percentage_by_channels
    FROM yearly_sales ys
    INNER JOIN total_sales t ON ys.country_region = t.country_region AND ys.calendar_year = t.calendar_year),  
		lagged_data AS (
    	SELECT
        country_region,
        calendar_year,
        channel_desc,
        amount_sold,
        percentage_by_channels,
        LAG(percentage_by_channels) OVER (PARTITION BY country_region, channel_desc ORDER BY calendar_year ) AS percentage_previous_period 
    	FROM percentage_sales)
		    SELECT
		    country_region,
		    calendar_year,
		    channel_desc,
		    amount_sold,
		    percentage_by_channels || ' %' AS  "%_by channels",
		    COALESCE(percentage_previous_period, 0) || ' %' AS "%_previous_period", 
		    ROUND( percentage_by_channels - COALESCE(percentage_previous_period, 0),2)|| ' %' AS "%_difference"
			FROM lagged_data
			WHERE calendar_year BETWEEN 1999 AND 2001 
			ORDER BY country_region,calendar_year,channel_desc;
		    
		    	   
/* Task 2. Generate a sales report for the 49th, 50th, and 51st weeks of 1999.
Include a column named CUM_SUM to display the amounts accumulated during each week.
Include a column named CENTERED_3_DAY_AVG to show the average sales for the previous, current, and following days using a centered moving average.
For Monday, calculate the average sales based on the weekend sales (Saturday and Sunday) as well as Monday and Tuesday.
For Friday, calculate the average sales on Thursday, Friday, and the weekend.

Solution: The weekly_sales cte consist of the calculation of the sales and cumulative sales values and it also extracts the year, week number and day of the week for the moving average calculation.
Cumulative sales was calculated using the RANGE frame to ensure that the sales figures are calculated from the start of each week up to the current row.
The 3-day moving average calculation uses a CASE statement and additionally I used INTERVAL with RANGE frame to define the window based on the date rather than the row position.
The filtering is done after all calculations are complete to ensure that the necessary data for all weeks and days is included, and only the relevant weeks (49,50,51) are selected for the final output*/ 
		   
SELECT * FROM (
WITH weekly_sales AS (
SELECT 
sum(s.amount_sold) AS sales,
EXTRACT (YEAR FROM s.time_id) AS sales_year,
date_part('week', s.time_id) AS week_num,
trim(to_char(s.time_id, 'day')) AS day_name,
s.time_id AS date,
sum(sum(s.amount_sold)) OVER (PARTITION BY date_part('week', s.time_id),EXTRACT (YEAR FROM s.time_id) ORDER BY s.time_id asc RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales
FROM sh.sales s 
GROUP BY s.time_id
ORDER BY s.time_id)
		SELECT 
		ws.sales,
		ws.week_num, 
		ws.day_name,
		ws.date,
		ws.cum_sales,
		ws.sales_year,
		CASE 
        WHEN lower(ws.day_name) = 'friday' THEN round(AVG(ws.sales)  OVER (ORDER BY ws.date RANGE BETWEEN INTERVAL '1 day' PRECEDING AND INTERVAL '2 days' FOLLOWING),2)
        WHEN lower(ws.day_name) = 'monday' THEN round(AVG(ws.sales)  OVER ( ORDER BY ws.date RANGE BETWEEN INTERVAL '2 day' PRECEDING AND INTERVAL '1 days' FOLLOWING),2)  
        ELSE   round(AVG(ws.sales)  OVER ( ORDER BY ws.date RANGE BETWEEN INTERVAL '1 day' PRECEDING AND INTERVAL '1 days' FOLLOWING),2) 
		END AS centered_3_day_avg
		FROM weekly_sales ws
		ORDER BY ws.date) AS sub
		WHERE EXTRACT (YEAR FROM sub.date )= 1999 AND sub.week_num IN (49,50,51);

/* Task 3. Please provide 3 instances of utilizing window functions that include a frame clause, using RANGE, ROWS, and GROUPS modes. */

/* In the first query, the frame clause is defined using ROWS mode in order to calculate the cumulative sales. This means that the calculation will sum up all previous rows from the first quarter up to the current quarter within the partition, which is split by product and year. 
 * Reason for choosing the ROWS mode is to ensure that it considers all rows in the sequence (based on the quarter) */
SELECT 
p.prod_id,
p.prod_name,
EXTRACT (year FROM s.time_id)||' Q'||EXTRACT (quarter FROM s.time_id) AS quarter,
sum(s.amount_sold) AS sales,
SUM(sum(s.amount_sold)) OVER (PARTITION BY p.prod_id,EXTRACT (year FROM s.time_id) ORDER BY EXTRACT (quarter FROM s.time_id) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM sh.sales s 
INNER JOIN sh.products p ON s.prod_id = p.prod_id
GROUP BY  EXTRACT (year FROM s.time_id),EXTRACT (quarter FROM s.time_id), p.prod_id
ORDER BY p.prod_id;
    
/*The second query uses GROUPS mode for calculating a 3 month moving average of sales values for each product. The GROUPS frame is used to make sure that each group of rows with the same prod_id is considered together, and only rows within the defined window meaning the current month and the next two months are considered in the calculation. */ 

WITH product_sales AS (
SELECT 
p.prod_id,
EXTRACT(YEAR FROM s.time_id) || ' ' || LPAD((EXTRACT(MONTH FROM s.time_id):: TEXT), 2, '0') AS month,
SUM(s.amount_sold) AS total_sales
FROM sh.sales s
INNER JOIN sh.products p ON s.prod_id = p.prod_id
WHERE EXTRACT(YEAR FROM s.time_id) = 2000
GROUP BY p.prod_id, EXTRACT(YEAR FROM s.time_id), EXTRACT(MONTH FROM s.time_id))
	SELECT 
    ps.prod_id,
    ps.month,
    ps.total_sales,
    round(AVG(ps.total_sales) OVER (PARTITION BY ps.prod_id ORDER BY ps.month GROUPS BETWEEN CURRENT ROW AND 2 FOLLOWING ),2) AS moving_avg_sales    
    FROM product_sales ps
    ORDER BY ps.prod_id, ps.month;

/*Third query uses the RANGE mode to retrieve similar revenue calculations for different price ranges (for prices within a 10 dollar difference of the current price).
 * The RANGE frame is used in this case because it allows the window to expand based on the value of amount_sold (price of the product) */
   
WITH summarized_sales AS (
SELECT 
s.amount_sold,  
SUM(s.amount_sold) AS total_sales,  
SUM(s.quantity_sold) AS total_quantity  
FROM sh.sales s
GROUP BY s.amount_sold 
	SELECT 
    ss.amount_sold AS price_list, 
    ss.total_sales,  
    ss.total_quantity,  
    SUM(ss.total_sales) OVER (ORDER BY ss.amount_sold RANGE BETWEEN  10 PRECEDING AND  10 FOLLOWING) AS similar_revenue
	FROM summarized_sales ss
	ORDER BY price_list desc;