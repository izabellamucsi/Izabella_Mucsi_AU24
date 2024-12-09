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
 * The function calculates the average sales quantity for a specific product, grouping the results by region. It takes a product name as input parameter and returns a table with the average sales quantity, product details, and region information.
 * If the input product name does not match any records, a raise notice is displayed indicating that the product was not found.*/

--DROP FUNCTION sh.average_sales_quantity(text);
CREATE OR REPLACE FUNCTION sh.average_sales_quantity (IN p_product_name TEXT)   
RETURNS TABLE (
    returned_avg_sales_quantity NUMERIC,
    returned_product_name varchar,
    retuned_product_id integer,
    returned_region varchar)
LANGUAGE plpgsql 
AS $$
BEGIN
    RETURN QUERY
    SELECT 
    AVG(s.quantity_sold) AS returned_avg_sales_quantity, 
    p.prod_name AS returned_product_name,
	p.prod_id as retuned_product_id,
	c2.country_region
    FROM sh.sales s   
    INNER JOIN sh.products p ON s.prod_id = p.prod_id
    INNER JOIN sh.customers c ON s.cust_id = c.cust_id
    INNER JOIN sh.countries c2 ON c2.country_id = c.country_id  
    WHERE  p.prod_name = p_product_name
    GROUP BY p.prod_id, c2.country_region;
    IF NOT FOUND THEN
        RAISE NOTICE 'The product name % was not found', p_product_name;
    END IF;
END;
$$;

SELECT * FROM sh.average_sales_quantity('Laptop carrying case');


/* Task 3.3 Find the top five customers with the highest total sales amount.
 * The sh.top_5_customers() function retrieves the top 5 customers based on their total sales amount, including their customer ID, full name, and total sales. Finding the top 5 sales value can 
 * be solved by using the limit 5 clause or using a subquery, in case multiple customers have identical sales values. I choose the first method, using limit by 5.  */

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
    ORDER BY sales_amount DESC
	LIMIT 5;   
END;
$$;
--Testing the function
SELECT * FROM sh.top_5_customers();