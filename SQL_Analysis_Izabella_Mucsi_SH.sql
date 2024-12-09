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
 * The function calculates the average sales quantity per region for a specified product and returns both the average sales quantity and the product ID.
 * The calculation was done by using ctes. In the first step, (qty_sold_per_product) it calculates the total quantity sold per product and 
 * the number of distinct regions each product was sold in (qty_sold_per_region).The final select statement divides the total quantity by the number of regions to get the average for each product.
 * If the input product ID does not match any records, a raise notice is displayed indicating that the product ID was not found.*/

CREATE OR REPLACE FUNCTION sh.average_sales_quantity (IN p_product_id INTEGER) 
RETURNS TABLE (
	returned_avg_sales_quantity NUMERIC,
	returned_product_id INTEGER) 
LANGUAGE plpgsql 
AS $$
BEGIN
    RETURN QUERY
    WITH qty_sold_per_product AS (
    SELECT 
    SUM(s.quantity_sold) AS qty_product, 
    s.prod_id
    FROM sh.sales s 
    WHERE p_product_id = s.prod_id 
    GROUP BY s.prod_id ),
    	qty_sold_per_region AS (
        SELECT  
        COUNT(DISTINCT c2.country_region) AS number_of_regions, 
        s.prod_id
        FROM sh.sales s 
        INNER JOIN sh.customers c ON s.cust_id = c.cust_id 
        INNER JOIN sh.countries c2 ON c2.country_id = c.country_id 
        GROUP BY s.prod_id)
	    	SELECT  
	        (spp.qty_product / spr.number_of_regions) AS returned_avg_sales_quantity, 
	        spp.prod_id AS returned_product_id
	    	FROM qty_sold_per_product spp
	    	INNER JOIN qty_sold_per_region spr ON spr.prod_id = spp.prod_id;
    IF NOT FOUND THEN
        RAISE NOTICE 'The product id % was not found', p_product_id;			
    END IF;
END;
$$;

SELECT * FROM sh.average_sales_quantity(14);


/* Task 3.3 Find the top five customers with the highest total sales amount.
 * The sh.top_5_customers() function retrieves the top 5 customers based on their total sales amount, including their customer ID, full name, and total sales. Finding the top 5 sales value can 
 * be solved by using the limit 5 clause or using a subquery. In case multiple customers have identical sales values I choose the second method, including a subquery.  */

CREATE OR REPLACE FUNCTION sh.top_5_customers()
RETURNS TABLE (
    customer_id INTEGER,
    customer_name TEXT,
    sales_amount NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
    c.cust_id AS customer_id,
    CONCAT(c.cust_first_name, ' ', c.cust_last_name) AS customer_name,
    SUM(s.amount_sold) AS sales_amount
    FROM sh.customers c    
    INNER JOIN sh.sales s  ON s.cust_id = c.cust_id
    GROUP BY c.cust_id
    HAVING SUM(s.amount_sold) >= (
      SELECT MIN(sub.sales_amount)
      FROM (
            SELECT SUM(s2.amount_sold) AS sales_amount   --subquery for determining the top 5 highest value in case of tied rows
            FROM sh.sales s2
            GROUP BY s2.cust_id  
            ORDER BY  sales_amount DESC 
            LIMIT 5) AS sub)
    ORDER BY sales_amount DESC;   
END;
$$;
--Testing the function
SELECT * FROM sh.top_5_customers();