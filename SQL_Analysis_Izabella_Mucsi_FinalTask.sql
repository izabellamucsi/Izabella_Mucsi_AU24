/*Task 1. Create a query to generate a report that identifies for each channel and throughout the entire period, the regions with the highest quantity of products sold (quantity_sold).
 * Solution: The ranked_data subquery calculates  the total sales for each region within a channel using the window function and also calculates the total sales for each channel.
 * Additionally, it assigns a rank to each region based on their total sales using the RANK function. This rank is used in the outer query to make sure that only the region with the highest sales is selected for each channel.
The outer query also includes the sales percentage column which was calculated by dividing the region's sales by the total channel sales. */

SELECT 
channel_desc,
country_region,
sales,
ROUND((sales / total_channel_sales)*100, 2) || '%' AS "sales %"									--Percentage of sales for the region compared to total channel sales
FROM (
  		SELECT 
        c.channel_desc AS channel_desc,
        c3.country_region AS country_region,
        round(SUM(s.quantity_sold),2) AS sales,
        SUM(SUM(s.quantity_sold)) OVER (PARTITION BY c.channel_desc) AS total_channel_sales,
        RANK() OVER (PARTITION BY c.channel_desc ORDER BY SUM(s.quantity_sold) DESC) AS rank
    	FROM sh.sales s
    	INNER JOIN sh.channels c ON s.channel_id = c.channel_id
    	INNER JOIN sh.customers c2 ON s.cust_id = c2.cust_id
    	INNER JOIN sh.countries c3 ON c3.country_id = c2.country_id
    	GROUP BY c.channel_desc, c3.country_region) ranked_data
WHERE rank = 1																					 --Selecting only the top-ranked region
ORDER BY sales DESC;

/*Task 2. Identify the subcategories of products with consistently higher sales from 1998 to 2001 compared to the previous year.
 * Solution: The query shows those product subcategories that had an increase in sales every year from 1998 to 2001. This was achieved by using the LAG function to find the subcategories where sales were higher than the previous year for all four years in the range.
 * The LAG() function  retrieved the sales of the previous year for each subcategory and the CASE statement was used to determine if the sales in the current year is higher than the sales in the previous year. 
 * Only subcategories with a count of four years are included in the final result. */

WITH yearly_sales AS (
SELECT 
p.prod_subcategory,
p.prod_subcategory_id,
EXTRACT(YEAR FROM s.time_id) AS sales_year,
SUM(s.amount_sold) AS sales_current_year,
COALESCE(LAG(SUM(s.amount_sold)) OVER (PARTITION BY p.prod_subcategory ORDER BY EXTRACT(YEAR FROM s.time_id)),0) AS sales_prev_year  --Total sales for the previous year, using LAG function
FROM sh.sales s
INNER JOIN sh.products p ON s.prod_id = p.prod_id
WHERE EXTRACT(YEAR FROM s.time_id) BETWEEN 1998 AND 2001
GROUP BY p.prod_subcategory_id,p.prod_subcategory, EXTRACT(YEAR FROM s.time_id))
	SELECT DISTINCT prod_subcategory
	FROM (
	    SELECT 
	        prod_subcategory,
	        prod_subcategory_id,
	        sales_year,
	        sales_current_year,
	        sales_prev_year,
	        CASE 
	            WHEN sales_current_year > sales_prev_year THEN 1 																	
	            ELSE 0 
	        END AS higher_sales
	    FROM yearly_sales) subquery
	WHERE higher_sales = 1																											--Filtering the subcategories with higher sales than the previous year
	GROUP BY prod_subcategory
	HAVING COUNT(DISTINCT sales_year) = 4;																

/*Task 3.reate a query to generate a sales report for the years 1999 and 2000, focusing on quarters and product categories. In the report you have to  analyze the sales of products from the categories 'Electronics,' 'Hardware,' and 'Software/Other,' across the distribution channels 'Partners' and 'Internet'.
 * Solution A: The query filters the data to include only the specified years, product categories, and distribution channels in order to calculate the cumulative sum of sales by quarter and the total sales for each product category for each quarter.
 * In order to calculate the percentage by which sales increased or decreased compared to the first quarter of the year the FIRST_VALUE function was used which retrieves the sales amount from the first quarter for each product category. The diff_percent column shows the difference between the current quarter's sales and the first quarter's sales.*/

SELECT 
EXTRACT(YEAR FROM s.time_id) AS calendar_year,
concat(EXTRACT(YEAR FROM s.time_id),'-',(lpad(EXTRACT(QUARTER FROM s.time_id)::text,2,'0'))) AS calendar_quarter_desc,
p.prod_category AS prod_category,
ROUND(SUM(s.amount_sold), 2) AS sales$,
CASE 
	WHEN EXTRACT(QUARTER FROM s.time_id) = 1 THEN 'N/A'
	ELSE ROUND((SUM(s.amount_sold) - FIRST_VALUE(SUM(s.amount_sold)) OVER (PARTITION BY EXTRACT(YEAR FROM s.time_id),p.prod_category ORDER BY EXTRACT(QUARTER FROM s.time_id))) * 100.0 /  FIRST_VALUE(SUM(s.amount_sold)) OVER ( PARTITION BY EXTRACT(YEAR FROM s.time_id), p.prod_category ORDER BY EXTRACT(QUARTER FROM s.time_id)), 2 ) || '%'    --Calculating the percentage difference compared to Q1 sales
END AS diff_percent,
ROUND(SUM(SUM(s.amount_sold)) OVER (PARTITION BY EXTRACT(YEAR FROM s.time_id), EXTRACT(quarter FROM s.time_id) ORDER BY EXTRACT(QUARTER FROM s.time_id)), 2) AS cum_sum$   																																											  --Cumulative sum of sales for the quarters
FROM sh.sales s 
INNER JOIN sh.products p ON s.prod_id = p.prod_id
INNER JOIN sh.channels c ON s.channel_id = c.channel_id
WHERE EXTRACT(YEAR FROM s.time_id) BETWEEN 1999 AND 2000
AND lower(p.prod_category) IN ('electronics', 'hardware', 'software/other')
AND lower(c.channel_desc) IN ('partners', 'internet')
GROUP BY EXTRACT(YEAR FROM s.time_id),EXTRACT(QUARTER FROM s.time_id), p.prod_category
ORDER BY calendar_year,calendar_quarter_desc,sales$ DESC;

/*Solution B: The query uses WINDOW frames with RANGE mode to define the cumuative sum values. As the task required time based grouping the range mode was appropriate for calculating cumulative sums and percentage differences based quarters and years. */

SELECT 
EXTRACT(YEAR FROM s.time_id) AS calendar_year,
concat(EXTRACT(YEAR FROM s.time_id),'-',(lpad(EXTRACT(QUARTER FROM s.time_id)::text,2,'0'))) AS calendar_quarter_desc,
p.prod_category AS prod_category,
ROUND(SUM(s.amount_sold), 2) AS sales$,
CASE 
	WHEN EXTRACT(QUARTER FROM s.time_id) = 1 THEN 'N/A'
	ELSE ROUND((SUM(s.amount_sold) - FIRST_VALUE(SUM(s.amount_sold)) OVER (PARTITION BY EXTRACT(YEAR FROM s.time_id), prod_category ORDER BY EXTRACT(QUARTER FROM s.time_id) RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)) * 100 /  FIRST_VALUE(SUM(s.amount_sold)) OVER (PARTITION BY EXTRACT(YEAR FROM s.time_id), prod_category ORDER BY EXTRACT(QUARTER FROM s.time_id) RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), 2 ) || '%'        
END AS diff_percent,
SUM(SUM(s.amount_sold)) OVER (PARTITION BY EXTRACT(YEAR FROM s.time_id), EXTRACT(quarter FROM s.time_id) ORDER BY EXTRACT(YEAR FROM s.time_id) RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sum$   																																											
FROM sh.sales s 
INNER JOIN sh.products p ON s.prod_id = p.prod_id
INNER JOIN sh.channels c ON s.channel_id = c.channel_id
WHERE EXTRACT(YEAR FROM s.time_id) BETWEEN 1999 AND 2000
AND lower(p.prod_category) IN ('electronics', 'hardware', 'software/other')
AND lower(c.channel_desc) IN ('partners', 'internet')
GROUP BY EXTRACT(YEAR FROM s.time_id),EXTRACT(QUARTER FROM s.time_id), p.prod_category
ORDER BY calendar_year,calendar_quarter_desc,sales$ DESC;