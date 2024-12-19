/* Task 4. Cretating the database named household_store with the schema store and cretaing the tables*/
DROP DATABASE IF EXISTS household_store;		
CREATE DATABASE household_store;		
COMMIT;	

-- Connecting to the household_store database before creating the schema
CREATE SCHEMA IF NOT EXISTS store;
COMMIT;	

/* Creating tables */

--DROP TABLE IF EXISTS store.Customer;
CREATE TABLE IF NOT EXISTS store.Customer (
    customer_id serial PRIMARY KEY,
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL,
    email varchar(50) UNIQUE CHECK (email LIKE '%@%.%'),
    phone varchar(50),
    created_at timestamp without time zone NULL DEFAULT current_date CHECK (created_at >= '2024-07-01'));

--DROP TABLE IF EXISTS store.Employees;
CREATE TABLE IF NOT EXISTS store.Employees (
    employee_id serial PRIMARY KEY,
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL,
    position varchar(50),
    hire_date date,
    salary numeric NULL CHECK (salary > 0));
    
--DROP TABLE IF EXISTS store.Suppliers;
CREATE TABLE IF NOT EXISTS store.Suppliers (
    supplier_id serial PRIMARY KEY,
    supplier_name varchar(50) NOT NULL UNIQUE,
    contact_name varchar(50) NOT NULL,
    address varchar(50));
    
--DROP TABLE IF EXISTS store.Products;
CREATE TABLE IF NOT EXISTS store.Products (
    product_id serial PRIMARY KEY,
    product_name varchar(50) NOT NULL,
    brand varchar(50),
    model varchar(50) UNIQUE,
    category varchar(50),
    price numeric NULL CHECK (price > 0));
    
--DROP TABLE IF EXISTS store.Orders;
CREATE TABLE IF NOT EXISTS store.Orders (
    order_id serial PRIMARY KEY, 
    customer_id integer, 
    order_date date,
    employee_id integer,
    status varchar(50) CHECK (status IN ('pending', 'delivered')),
    total_amount numeric CHECK (total_amount >= 0),
    order_year integer GENERATED ALWAYS AS (EXTRACT(YEAR FROM order_date)) STORED,
    CONSTRAINT fk_customer_orders FOREIGN KEY (customer_id) REFERENCES store.Customer (customer_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
   	CONSTRAINT fk_employee_orders FOREIGN KEY (employee_id) REFERENCES store.Employees (employee_id) ON DELETE SET NULL ON UPDATE NO ACTION);

--DROP TABLE IF EXISTS store.Orders_items;
CREATE TABLE IF NOT EXISTS store.Orders_items (
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC CHECK (unit_price > 0),
    PRIMARY KEY (order_id, product_id),
    CONSTRAINT fk_orders_items_orders FOREIGN KEY (order_id) REFERENCES store.Orders (order_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_orders_items_products FOREIGN KEY (product_id) REFERENCES store.Products (product_id) ON DELETE NO ACTION ON UPDATE NO ACTION);
    
--DROP TABLE IF EXISTS store.Inventory_tracking;
CREATE TABLE IF NOT EXISTS store.Inventory_tracking (
    inventory_tracking_id serial PRIMARY KEY,
    product_id integer,
    transaction_date date CHECK (transaction_date >= '2024-07-01'),
    transaction_type varchar(50) CHECK (transaction_type IN ('sold', 'returned')),
   	quantity integer,
    CONSTRAINT fk_product_inventory_tracking FOREIGN KEY (product_id) REFERENCES store.Products (product_id) ON DELETE NO ACTION ON UPDATE NO ACTION);
   	
   
--DROP TABLE IF EXISTS store.Product_Suppliers;
CREATE TABLE IF NOT EXISTS store.Product_Suppliers (
    product_id INTEGER,
    supplier_id INTEGER,
    supply_date DATE CHECK (supply_date >= '2024-07-01'),
    PRIMARY KEY (product_id, supplier_id),
    CONSTRAINT fk_product_suppliers_products FOREIGN KEY (product_id) REFERENCES store.Products (product_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_product_suppliers_suppliers FOREIGN KEY (supplier_id) REFERENCES store.Suppliers (supplier_id) ON DELETE NO ACTION ON UPDATE NO ACTION);
   
--Inserting data into the customer table  
WITH customer_data AS (
    SELECT * FROM (VALUES
        ('Alice', 'Smith', 'alice.smith@email.com', '123-456-7890'),
        ('Bob', 'Johnson', 'bob.johnson@email.com', '234-567-8901'),
        ('Charlie', 'Williams', 'charlie.williams@email.com', '345-678-9012'),
        ('David', 'Brown', 'david.brown@email.com', '456-789-0123'),
        ('Eva', 'Davis', 'eva.davis@email.com', '567-890-1234'),
        ('Frank', 'Miller', 'frank.miller@email.com', '678-901-2345')) AS d (first_name, last_name, email, phone))
INSERT INTO store.Customer (first_name, last_name, email, phone)
SELECT first_name, last_name, email, phone
FROM customer_data
WHERE NOT EXISTS (
    SELECT 1
    FROM store.Customer
    WHERE email = customer_data.email);
	COMMIT;
   
--Inserting data into the employees table

WITH employees_data AS (
    SELECT * FROM (VALUES
        ('Oliver', 'Knight', 'Store Manager', '2024-09-01'::date, 60000.00),
        ('Charlotte', 'Dubois', 'Assistant of the Store Manager', '2024-09-01'::date, 45000.00),
        ('Noah', 'Johnson', 'Visual Merchandiser', '2024-10-01'::date, 40000.00),
        ('Ava', 'Connor', 'Cashier', '2024-10-05'::date, 30000.00),
        ('Leo', 'Rossi', 'Stocker', '2024-10-20'::date, 28000.00),
        ('Emilia', 'Martinez', 'Seller', '2024-10-31'::date, 35000.00)) AS d (first_name, last_name, position, hire_date, salary))
	INSERT INTO store.Employees (first_name, last_name, position, hire_date, salary)
	SELECT first_name, last_name, position, hire_date, salary
	FROM employees_data
	WHERE NOT EXISTS (
	    SELECT 1
	    FROM store.Employees
	    WHERE first_name = employees_data.first_name AND last_name = employees_data.last_name);
		COMMIT;

--Inserting data into the suppliers table	

WITH suppliers_data AS (
    SELECT * FROM (VALUES
        ('Home Interiors and Gifts', 'James Clark', '123 Elm Street, Springfield'),
        ('Office Goods', 'Linda Allen', '456 Oak Avenue, Metropolis'),
        ('Furniture Mart', 'Robert White', '789 Pine Road, Gotham'),
        ('Home Depot', 'Mary Green', '101 Maple Lane, Star City'),
        ('Bed Bath & Beyond', 'David Harris', '202 Birch Drive, Central City'),
        ('Jysk', 'Sarah Moore', '303 Cedar Way, Smallville')) AS d (supplier_name, contact_name, address))
	INSERT INTO store.Suppliers (supplier_name, contact_name, address)
	SELECT supplier_name, contact_name, address
	FROM suppliers_data
	WHERE NOT EXISTS (
	    SELECT 1
	    FROM store.Suppliers
	    WHERE supplier_name = suppliers_data.supplier_name);
		COMMIT;

--Inserting data into the products table

WITH products_data AS (
    SELECT 'Vacuum Cleaner' AS product_name, 'Dyson' AS brand, 'V11' AS model, 'Cleaning' AS category, 499.99 AS price
    UNION ALL
    SELECT 'Microwave Oven', 'Samsung', 'ME18H704SFS', 'Kitchen Appliance', 199.99
    UNION ALL
    SELECT 'Blender', 'Ninja', 'BL660', 'Kitchen Appliance', 99.99
    UNION ALL
    SELECT 'Air Purifier', 'Honeywell', 'HPA300', 'Home Comfort', 249.99
    UNION ALL
    SELECT 'Dishwasher', 'Bosch', 'SHXM78W55N', 'Kitchen Appliance', 799.99
    UNION ALL
    SELECT 'Refrigerator', 'Whirlpool', 'WRF535SWHZ', 'Kitchen Appliance', 1200.00)
INSERT INTO store.Products (product_name, brand, model, category, price)
SELECT pd.product_name, pd.brand, pd.model, pd.category, pd.price
FROM products_data pd
WHERE NOT EXISTS (
    SELECT 1
    FROM store.Products p
    WHERE p.product_name = pd.product_name)
	RETURNING product_id, product_name, brand, model, category, price;
	COMMIT;

--Inserting data into the orders table

WITH employee_id AS (
    SELECT employee_id
    FROM store.Employees
    WHERE lower(POSITION) = 'cashier'
    LIMIT 1),
	new_orders AS (
    SELECT 1 AS customer_id, '2024-09-10'::DATE AS order_date, (SELECT employee_id FROM employee_id) AS employee_id,'delivered' AS status, 1500.00 AS total_amount
    UNION ALL
    SELECT 2, '2024-09-15'::DATE, (SELECT employee_id FROM employee_id), 'delivered', 250.00
    UNION ALL
    SELECT 3, '2024-09-02'::DATE, (SELECT employee_id FROM employee_id), 'pending', 500.00
    UNION ALL
    SELECT 4, '2024-11-11'::DATE, (SELECT employee_id FROM employee_id), 'delivered', 1250.00
    UNION ALL
    SELECT 5, '2024-10-01'::DATE, (SELECT employee_id FROM employee_id), 'pending', 750.00
    UNION ALL
    SELECT 6, '2024-10-20'::DATE, (SELECT employee_id FROM employee_id), 'delivered', 300.00)
		INSERT INTO store.orders (customer_id, order_date, employee_id, status, total_amount)
		SELECT no.customer_id, no.order_date, no.employee_id, no.status, no.total_amount
		FROM new_orders no
		WHERE NOT EXISTS (
		    SELECT 1
		    FROM store.Orders o
		    WHERE o.customer_id = no.customer_id AND o.order_date = no.order_date)
			RETURNING order_id, customer_id, order_date, employee_id, status, total_amount;
			COMMIT;

--Inserting data into the orders_items table

WITH order_items_data AS (
    SELECT 1 AS order_id, 1 AS product_id, 2 AS quantity, 1200.00 AS unit_price
    UNION ALL
    SELECT 2, 2, 1, 800.00
    UNION ALL
    SELECT 3, 3, 3, 500.00
    UNION ALL
    SELECT 4, 4, 5, 200.00
    UNION ALL
    SELECT 5, 5, 1, 100.00
    UNION ALL
    SELECT 6, 6, 2, 40.00)
		INSERT INTO store.orders_items(order_id, product_id, quantity, unit_price)
		SELECT oi.order_id, oi.product_id, oi.quantity, oi.unit_price
		FROM order_items_data oi
		RETURNING order_id, product_id, quantity, unit_price;
		COMMIT;

--Inserting data into the inventory_tracking table

WITH inventory_tracking_data AS (
    SELECT 1 AS product_id, '2024-09-05'::DATE AS transaction_date, 'sold' AS transaction_type, 20 AS quantity
    UNION ALL
    SELECT 2, '2024-09-12'::DATE, 'returned', 10
    UNION ALL
    SELECT 3, '2024-10-01'::DATE, 'sold', 50
    UNION ALL
    SELECT 4, '2024-10-10'::DATE, 'sold', 30
    UNION ALL
    SELECT 5, '2024-11-03'::DATE, 'returned', 100
    UNION ALL
    SELECT 6, '2024-11-15'::DATE, 'sold', 80)
		INSERT INTO store.Inventory_Tracking (product_id, transaction_date, transaction_type, quantity)
		SELECT ni.product_id, ni.transaction_date, ni.transaction_type, ni.quantity
		FROM inventory_tracking_data ni
		RETURNING product_id, transaction_date, transaction_type, quantity;
		COMMIT;
	
--Inserting data into the product_suppliers table	
	
WITH product_suppliers_data AS ( 
    SELECT 1 AS product_id, 1 AS supplier_id, '2024-09-01'::DATE AS supply_date
    UNION ALL
    SELECT 2, 2, '2024-09-15'::DATE
    UNION ALL
    SELECT 3, 3, '2024-09-20'::DATE
    UNION ALL
    SELECT 4, 4, '2024-10-12'::DATE
    UNION ALL
    SELECT 5, 5, '2024-11-01'::DATE
    UNION ALL
    SELECT 6, 6, '2024-11-20'::DATE)
		INSERT INTO store.Product_Suppliers (product_id, supplier_id, supply_date)
		SELECT psd.product_id, psd.supplier_id, psd.supply_date
		FROM product_suppliers_data psd
		WHERE NOT EXISTS (
		    SELECT 1
		    FROM store.Product_Suppliers ps
		    WHERE ps.product_id = psd.product_id AND ps.supplier_id = psd.supplier_id)
			RETURNING product_id, supplier_id, supply_date;
			COMMIT;

--Checking the populated tables 			
SELECT * FROM store.customer c; 
SELECT * FROM store.employees e; 
SELECT * FROM store.suppliers s; 
SELECT * FROM store.products p; 
SELECT * FROM store.orders o; 
SELECT * FROM store.orders_items oi; 
SELECT * FROM store.inventory_tracking it; 
SELECT * FROM store.product_suppliers ps; 

/* Task 5.1 Create a function that updates data in one of your tables. 
 * The function, update_customer_table, allows to update a specific customer record in the store.customer table and retrieve the updated information using the returning clause.
 * I have updated the  function body to check the existence of the provided p_customer_id parameter in the store.customer table anf if no matching customer is found, a raise notice is displayed and the function won't perform any updates.*/

--DROP FUNCTION store.new_record(text, date, int4);
CREATE OR REPLACE FUNCTION update_customer_table( p_customer_id INT, p_column_name TEXT,p_new_value TEXT)
RETURNS TABLE(
    result_customer_id INT,
    result_first_name VARCHAR,
    result_last_name VARCHAR,
    result_phone VARCHAR,
    result_email VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    update_statement TEXT;
BEGIN
	IF NOT EXISTS (SELECT 1 FROM store.customer c WHERE p_customer_id = c.customer_id) THEN
		RAISE NOTICE 'customer with the customer_id % parameter does not exist',p_customer_id;
	RETURN;
	ELSE
      update_statement := concat('UPDATE store.customer SET ', p_column_name, ' = ''',  p_new_value, '''', ' WHERE customer_id = ', p_customer_id, ';');
    	RAISE NOTICE 'The record has been updated';
    	EXECUTE update_statement;
    	RETURN QUERY 
    	SELECT 
        c.customer_id AS result_customer_id, 
        c.first_name AS result_first_name,
        c.last_name AS result_last_name,
        c.phone AS result_phone, 
        c.email AS result_email
    	FROM 
        store.customer c
    	WHERE 
        c.customer_id = customer_id;
end if;
END;
$$;



SELECT * FROM update_customer_table(22, 'phone', '812-022');
SELECT * FROM store.customer c;

/*Task 5.2 Create a function that adds a new transaction to your transaction table.
 * The function new_record inserts a new row into the inventory_tracking table. It checks for existing records based on the product_model, action_date, and amount.
 * If a matching record doesn't exist, it inserts a new record and returns the inserted data. */

CREATE OR REPLACE FUNCTION store.new_record(IN product_model text,IN action_date date,IN amount integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    new_inventory_tracking_id integer;
BEGIN
    IF EXISTS (
        SELECT 1
        FROM store.inventory_tracking it
        WHERE it.transaction_date = action_date
          AND it.quantity = amount
          AND it.product_id = (
              SELECT p.product_id
              FROM store.products p
              WHERE p.model = product_model
              LIMIT 1))
    THEN
        RAISE NOTICE 'Record already exists.';
    ELSE
        WITH model_identification AS (
            SELECT p.product_id 
            FROM store.products p
            WHERE p.model = product_model
            LIMIT 1),
        	transaction_type_identification AS (
            SELECT CASE 
                       WHEN amount > 0 THEN 'sold'
                       ELSE 'returned'
                   END AS type_definition)
        INSERT INTO store.inventory_tracking(product_id, transaction_date, transaction_type, quantity)
        SELECT 
            mi.product_id,
            action_date,
            tti.type_definition,
            amount
        FROM model_identification mi
        CROSS JOIN transaction_type_identification tti
        RETURNING inventory_tracking_id
        INTO new_inventory_tracking_id;
        RAISE NOTICE 'Record is added to the database.';
        RETURN new_inventory_tracking_id;
    END IF;
END;
$$;

SELECT * FROM store.new_record('V11','2024-08-01',5);
SELECT * FROM store.inventory_tracking it;

/* Task 6. Create a view that presents analytics for the most recently added quarter in your database.
 * This view calculates sales related metrics for the latest quarter, including total sales, order count, average order value, and sales grouped by product category. 
 * The results are sorted by quarter in descending order.*/

CREATE OR REPLACE VIEW quarterly_analytics AS
SELECT
    EXTRACT(QUARTER FROM order_date) AS quarter,
    SUM(total_amount) AS total_sales,
    COUNT(*) AS number_of_orders,
    AVG(total_amount) AS average_order_value,
    p.category AS product_category
FROM store.orders o
JOIN store.orders_Items oi ON o.order_id = oi.order_id
JOIN store.products p ON oi.product_id = p.product_id
WHERE EXTRACT(QUARTER FROM order_date) = (SELECT MAX(EXTRACT(QUARTER FROM order_date)) FROM store.orders)
GROUP BY EXTRACT(QUARTER FROM order_date), p.category
ORDER BY quarter DESC;
    
   
SELECT * FROM quarterly_analytics;

/* Task 7. Create a read-only role for the manager. This role should have permission to perform SELECT queries on the database tables, and also be able to log in.
 * The following anonymus DO block checks if the manager role exists and creates it if it doesn't, and then grants specific privileges on the household_store database and the store schema to the manager
 *  role if they haven't been granted already. Finally, a raise notice will be displayed to inform whether the role was created and privileges assigned.*/

DO $$ 
BEGIN 
    IF NOT EXISTS ( 
        SELECT 1 
        FROM pg_roles
        WHERE rolname = 'manager') 
        THEN 
		CREATE ROLE manager with password 'managers_password';
		RAISE NOTICE 'Role exist in the database';
		END IF;
		IF NOT EXISTS ( 
        SELECT 1 
        FROM information_schema.role_table_grants
        WHERE grantee = 'manager' 
          AND privilege_type IN ('SELECT')) THEN 
        GRANT CONNECT ON DATABASE household_store TO manager;
        GRANT USAGE ON SCHEMA store TO manager;
		GRANT SELECT ON ALL TABLES IN SCHEMA store TO manager;
		RAISE NOTICE 'Privileges have been assigned';
    ELSE 
        RAISE NOTICE 'Role already has assigned privileges';
    END IF;
END;
$$;



--Testing the manager role permission
SET ROLE manager;
SELECT current_user;
SELECT * FROM store.products;  --the role was granted selected permission therfore this select query will work
INSERT INTO store.suppliers		-- AS the role wasn't granted insert privilage this script will resukt in a error due to missing permissions
(supplier_name, contact_name, address)
VALUES('Appliance World', 'Emily Carter', '12 Main Street,Denver');

RESET ROLE;
