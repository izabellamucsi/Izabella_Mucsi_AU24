/* Task 1. - Create a query to produce a sales report highlighting the top customers with the highest sales across different sales channels. This report should list the top 5 customers for each channel. Additionally, calculate a key performance indicator (KPI) called 'sales_percentage,' which represents the percentage of a customer's sales relative to the total sales within their respective channel.
 * Solution - the query generates a sales report displaying the top 5 customers with the highest sales values across the different sales channels. The report also includes a sales_percentage KPI which was calculated for each customer
 * by dividing their total sales by the channel's total sales. I chose to use common tabe expressions to break down the solution into 3 steps. 
 * The first step (customer_channel_partition) calculates the total sales for each customer within each channel. 
 * The second cte (channel_partition) calculates the total sales for each channel and the third step (sales_percentage_calculation) combines the previous ctes and ranks the customers within each channel based on their sales using dense_rank in case customers have identical sales values. 
 * Finally the result set is filtered to show only the top 5 customers for each channel in descending order of total sales. */

WITH customer_channel_partition AS (
SELECT  c.cust_id, 
SUM(s.amount_sold) AS total_sales_amount,
CONCAT(c.cust_first_name, ' ', c.cust_last_name) AS customer_name,
c2.channel_id,
c2.channel_desc
FROM sh.sales s
INNER JOIN sh.customers c ON s.cust_id = c.cust_id 
INNER JOIN sh.channels c2 ON s.channel_id =  c2.channel_id 
GROUP BY  c.cust_id,c2.channel_id), 
	channel_partition AS (
	SELECT  
	sum(s.amount_sold) AS channel_sales,
	c2.channel_id,
	c2.channel_desc
	FROM sh.sales s
	INNER JOIN sh.channels c2 ON s.channel_id =  c2.channel_id 
	GROUP BY c2.channel_id
	ORDER BY channel_sales DESC,c2.channel_id ASC),
		sales_percentage_calculation AS (
		SELECT 
		round(total_sales_amount,2) AS total_sales_amount,
		round(((total_sales_amount / channel_sales)*100),5)||'%' AS sales_percentage,
		ccp.channel_id, 
		ccp.channel_desc, 
		ccp.customer_name,
		DENSE_RANK () OVER (PARTITION BY ccp.channel_id ORDER BY ((ccp.total_sales_amount / cp.channel_sales) * 100) DESC) AS customer_ranking
		FROM customer_channel_partition ccp
		INNER JOIN channel_partition cp  ON ccp.channel_id = cp.channel_id
		ORDER BY sales_percentage DESC)
			SELECT * 
			FROM sales_percentage_calculation spc
			WHERE spc.customer_ranking <= 5
			ORDER BY total_sales_amount desc;

/* Task 2. Create a query to retrieve data for a report that displays the total sales for all products in the Photo category in the Asian region for the year 2000. Calculate the overall report total and name it 'YEAR_SUM'.
 * Solution - the query generates a report displaying the total sales for all products in the Photo category in the Asian region during the year 2000 by displaying quarterly sales (Q1, Q2, Q3, Q4) and calculates an overall annual sales, named YEAR_SUM.
 * The solution uses the crosstab function to pivot quarterly sales data into columns.
 * Final result is sorted by YEAR_SUM in descending order using a cte. */

		
-- Enabling the tablefunc extension for the schema		
CREATE EXTENSION IF NOT EXISTS tablefunc SCHEMA sh;

WITH sorted_result AS (
SELECT 
    product_name,
    Q1,
    Q2,
    Q3,
    Q4,
    (COALESCE(Q1, 0) + COALESCE(Q2, 0) + COALESCE(Q3, 0) + COALESCE(Q4, 0)) AS total_year_sum
FROM sh.crosstab(
    'SELECT 
    p.prod_name,
    concat(''Q'', EXTRACT (quarter FROM s.time_id)) AS sales_quarter,
    round(sum(amount_sold),2) AS sales
	FROM sh.sales s
	INNER JOIN sh.products p ON s.prod_id = p.prod_id
	INNER JOIN sh.customers c ON s.cust_id = c.cust_id
	INNER JOIN sh.countries c2 ON c.country_id = c2.country_id
	WHERE p.prod_category_id = (SELECT p2.prod_category_id FROM sh.products p2 WHERE lower(p2.prod_category) = ''photo'' LIMIT 1)
    AND c2.country_region_id = (SELECT c3.country_region_id FROM sh.countries c3 WHERE lower(c3.country_region) = ''asia'' LIMIT 1)
    AND EXTRACT(YEAR FROM s.time_id) = 2000
	GROUP BY p.prod_name, EXTRACT (quarter FROM s.time_id)
	ORDER BY p.prod_name, sales_quarter',
	'VALUES (''Q1''), (''Q2''), (''Q3''), (''Q4'')')																				-- Defining the columns for crosstab function (quarters Q1 to Q4)
	AS result (product_name TEXT, Q1 NUMERIC, Q2 NUMERIC, Q3 NUMERIC, Q4 NUMERIC))
SELECT *																															--Retrieving data FROM the cte i ORDER TO  sort by the annual sales
FROM sorted_result
ORDER BY total_year_sum DESC;


/*Task 3. Create a query to generate a sales report for customers ranked in the top 300 based on total sales in the years 1998, 1999, and 2001. The report should be categorized based on sales channels, and separate calculations should be performed for each channel.
 * Solution - the  query uses ctes to break down the solution into steps. Ranked_sales cte calculates the total sales for each customer channel and year, it also ranks the customers by their total sales within each channel and year. 
 * In the next step, the second cte (filtered_customers) filters customers who are present in the top 300 rankings and then the final_customers query will display the list of customers who satisfy the previous condition for all three of the specified years (1998, 1999, and 2001) */

WITH ranked_sales AS (
SELECT
s.cust_id,
s.channel_id,
t.calendar_year,
SUM(s.amount_sold) AS total_sales,
RANK() OVER (PARTITION BY s.channel_id, t.calendar_year ORDER BY SUM(s.amount_sold) DESC) AS sales_rank    -- Ranking based on sales, channel and year
FROM sh.sales s
INNER JOIN sh.times t ON s.time_id = t.time_id
WHERE t.calendar_year IN (1998, 1999, 2001)
GROUP BY s.cust_id, s.channel_id, t.calendar_year),
	filtered_customers AS (
	SELECT
    rs.cust_id,
    rs.channel_id,
    COUNT(DISTINCT rs.calendar_year) AS qualifying_years
    FROM ranked_sales rs
    WHERE rs.sales_rank <= 300																				-- Filtering customers ranked in the top 300
    GROUP BY rs.cust_id, rs.channel_id),
		final_customers AS (
	    SELECT
	    fc.cust_id,
	    fc.channel_id
	    FROM filtered_customers fc
	    WHERE fc.qualifying_years = 3)																		-- Selecting customers who ranked in the top 300 for all three years 
			SELECT
		    c2.channel_desc,
		    c.cust_id,
		    c.cust_first_name || ' ' || c.cust_last_name AS customer_name,
		    ROUND(SUM(s.amount_sold), 2) AS total_sales
			FROM final_customers fc
			INNER JOIN sh.sales s ON fc.cust_id = s.cust_id AND fc.channel_id = s.channel_id
			INNER JOIN sh.customers c ON fc.cust_id = c.cust_id
			INNER JOIN sh.channels c2 ON fc.channel_id = c2.channel_id
			WHERE s.time_id IN (
		    SELECT time_id
		    FROM sh.times
		    WHERE calendar_year IN (1998, 1999, 2001))
			GROUP BY c2.channel_desc,c.cust_id
			ORDER BY c2.channel_desc, total_sales DESC;



/*Task 4.Create a query to generate a sales report for January 2000, February 2000, and March 2000 specifically for the Europe and Americas regions.
 * Solution - The query calculates the total sales for each product category for the months of January, February, and March of 2000 in the Europe and Americas regions. 
 * It uses the filter clause of the window functions to show the sales by region and by month. This task also could have been solved using a CASE WHEN statement to calculate regional sales.
 *  The data is grouped by product category, month and region to make sure that the report shows the sales for each product category Europe and Ameicas regions per month.*/
		
SELECT DISTINCT TO_CHAR(s.time_id, 'YYYY-MM') AS calendar_month_desc,
p.prod_category,
sum(SUM(s.amount_sold)) FILTER (WHERE lower(c2.country_region) = 'americas') OVER (PARTITION BY p.prod_category,  TO_CHAR(s.time_id, 'YYYY-MM')) AS Americas_sales, 	-- Total sales for the Americas by category and month
sum(SUM(s.amount_sold)) FILTER (WHERE lower(c2.country_region) = 'europe') OVER (PARTITION BY p.prod_category, TO_CHAR(s.time_id, 'YYYY-MM')) AS Europe_sales			-- Total sales for Europe by category and month
FROM sh.sales s
INNER JOIN  sh.products p ON s.prod_id = p.prod_id
INNER JOIN sh.customers c ON s.cust_id = c.cust_id
INNER JOIN sh.countries c2 ON c.country_id = c2.country_id
WHERE LOWER(c2.country_region) IN ('americas', 'europe') 
AND EXTRACT(YEAR FROM s.time_id) = 2000
AND EXTRACT(MONTH FROM s.time_id) IN (1, 2, 3)
GROUP BY TO_CHAR(s.time_id, 'YYYY-MM'),p.prod_category, c2.country_region
ORDER BY TO_CHAR(s.time_id, 'YYYY-MM'), p.prod_category;
    
   