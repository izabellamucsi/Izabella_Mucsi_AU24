/* Task 3.1.Retrieve the total sales amount for each product category for a specific time period.
 * The function called sales_product_category takes start_date and end_date as text inputs, which can be either full dates or just years. 
 * If only years are provided judging by the length of the input then it will append the input with -01-01 and -12-31 to the start and end dates, respectively, before using them to filter sales data by product category. */

--DROP FUNCTION sh.sales_product_category(text, text);
CREATE OR REPLACE FUNCTION sh.sales_product_category (
    IN start_date TEXT,  
    IN end_date TEXT)
RETURNS TABLE (
    product_category VARCHAR,
    sales_amount NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.prod_category, 
        SUM(s.amount_sold) AS sales_amount
    FROM 
        sh.sales s
    INNER JOIN 
        sh.products p ON s.prod_id = p.prod_id
    WHERE 
        s.time_id BETWEEN  CAST(CASE WHEN LENGTH(start_date) = 4 THEN start_date || '-01-01'	--Checking the length of the input parameter to prepare the start and end date for the where clause
                   				 ELSE start_date 
                				 END AS DATE) AND
            			   CAST(CASE WHEN LENGTH(end_date) = 4 THEN end_date || '-12-31'
                    			ELSE end_date 
                				END AS DATE)
    GROUP BY p.prod_category;    
END;
$$;

--Testing the functions
SELECT * FROM sh.sales_product_category('1998-01-01','1999-02-02');
SELECT * FROM sh.sales_product_category('1998','1999');

/*Task 3.2 Calculate the average sales quantity by region for a particular product.
 * The following query calculates the average quantity of products sold per region for each product. In the first step, (qty_sold_per_product) it calculates the total quantity sold per product and 
 * the number of distinct regions each product was sold in (qty_sold_per_region).The final select statement divides the total quantity by the number of regions to get the average for each product.*/

WITH qty_sold_per_product AS (
SELECT sum(s.quantity_sold) AS qty_product , s.prod_id 
FROM sh.sales s 
GROUP BY s.prod_id 
ORDER BY s.prod_id),
 qty_sold_per_region as(
SELECT  count(DISTINCT c2.country_region) AS number_of_regions,s.prod_id 
FROM sh.sales s 
INNER JOIN sh.customers c ON s.cust_id = c.cust_id 
INNER JOIN sh.countries c2 ON c2.country_id = c.country_id 
GROUP BY s.prod_id
ORDER BY s.prod_id)
SELECT  (spp.qty_product/spr.number_of_regions) AS average_sales_quantity, spp.prod_id
FROM qty_sold_per_product spp
INNER JOIN qty_sold_per_region spr ON spr.prod_id = spp.prod_id;


/* Task 3.3 Find the top five customers with the highest total sales amount.
 * This query identifies the top 5 customers with the highest total sales by summing their sales amounts, then retrieves their customer IDs, names, and sales amounts, sorted in descending order.*/

WITH top_5_sales_amount AS (SELECT sum(s.amount_sold) AS sales_amount
FROM sh.sales s 
GROUP BY s.cust_id
ORDER BY sales_amount DESC
LIMIT 5)
 SELECT c.cust_id, concat(c.cust_first_name, ' ', c.cust_last_name) AS customer_name, sum(s.amount_sold) AS sales_amount
 FROM sh.customers c 
 INNER JOIN sh.sales s ON s.cust_id = c.cust_id
GROUP BY c.cust_id
HAVING sum(s.amount_sold) IN (SELECT * FROM top_5_sales_amount)
ORDER BY sales_amount desc;