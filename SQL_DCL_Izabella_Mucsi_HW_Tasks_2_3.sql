/* 2.1 Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability to connect to the database but no other permissions.
There are two approaches for cretaing the role rentaluser, the first one under 2.1.1 would be a direct aproach wich doesn't allow flexibelity and the second one under 2.1.2 would be by using 
 anonymous DO block in order to avoid errors and check whether the user already exists */
--2.1.1 Direct approach

CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;
GRANT USAGE ON SCHEMA public TO rentaluser;


--2.1.2 anonymous DO block

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rentaluser') THEN
        CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
    END IF;
        GRANT CONNECT ON DATABASE dvdrental TO rentaluser;
        GRANT USAGE ON SCHEMA public TO rentaluser;
END;
$$;

/*2. Grant "rentaluser" SELECT permission for the "customer" table. Сheck to make sure this permission works correctly—write a SQL query to select all customers.
 * The script checks whether the role rentaluser has SELECT privilege on the customer table. If the role does not already have the privilege, the script grants the SELECT permission on the customer table
 * to the rentaluser role. If the privilege is already granted, a RAISE NOTICE message is displayed to inform that the privilage already exists.*/

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.role_table_grants
        WHERE grantee = 'rentaluser'
          AND table_name = 'customer'
          AND privilege_type = 'SELECT')
     THEN
        GRANT SELECT ON TABLE customer TO rentaluser;
		RAISE NOTICE 'The privilage is  granted';
	ELSE
		RAISE NOTICE 'The privilage is already granted';
    END IF;
END;
$$;

-- Checking if SELECT permission works as `rentaluser`:
SET ROLE rentaluser;
SELECT current_user;
SELECT * FROM public.customer; 	--the rentaluser should be able to use the select query 
SELECT * FROM public.film f;	--test to see that the rentalusert don't have permission for selecting other tables
RESET ROLE;

/*3. Create a new user group called "rental" and add "rentaluser" to the group. 
 * The following code checks whether a group named rental exists and if it doesn't then it will create the group and grants USAGE permission on the public schema to the group.
 * If the group already exists, the script displays a message indicating the group is already present.
 * I choose to use anonymus DO block because it allowed the conditional checks of IF NOT EXISTS.*/

DO $$
begin
	IF NOT EXISTS (SELECT 1
 		FROM pg_group WHERE groname = 'rental')
	THEN 
		CREATE GROUP rental;
		GRANT USAGE ON SCHEMA public TO rental;
		GRANT rental TO rentaluser;
		RAISE NOTICE 'Group is created';
	ELSE
		RAISE NOTICE 'Group already exists';
	END IF;
END;
$$;

/*4. Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. Insert a new row and update one existing row in the "rental" table under that role. 
 * In this script, I checked if the rental group has the necessary INSERT and UPDATE privileges on the rental table.
 * If the privileges have not yet been granted then the script assigns the SELECT, INSERT, and UPDATE privileges on the table to the rental group. 
 * If the privileges are already in place, RAISE NOTICE message will be displayed to inform that the privileges are already assigned.
 * To avoid hardcoding in the insert and update part of this task and to make sure that the code is reusable I granted select privilage to the rental group additionally 
 * to the film, staff, inventory, customer tables and to the rental sequence.*/

DO $$ 
BEGIN 
    IF NOT EXISTS ( 
        SELECT 1 
        FROM information_schema.role_table_grants
        WHERE grantee = 'rental' 
          AND table_name = 'rental' 
          AND privilege_type IN ('INSERT', 'UPDATE')
    ) THEN 
		GRANT SELECT ON public.rental TO rental;
		GRANT SELECT ON public.customer TO rental;
		GRANT SELECT ON public.inventory TO rental;
		GRANT SELECT ON public.film TO rental;
		GRANT SELECT ON public.staff TO rental;
        GRANT INSERT ON public.rental TO rental;
        GRANT UPDATE ON public.rental TO rental;
		GRANT USAGE, SELECT ON SEQUENCE public.rental_rental_id_seq TO rental;
		RAISE NOTICE 'Privileges have been assigned';
    ELSE 
        RAISE NOTICE 'Group already has assigned privileges';
    END IF;
END;
$$;

-- Checking if SELECT,INSERT,UPDATE permissions are working as for the rental group:
SET ROLE rental;
SELECT current_user;
RESET ROLE;

WITH renting_movies AS (                                                    
    SELECT 
        f.film_id AS film_id, 
        i.inventory_id AS inventory_id, 
        f.rental_rate AS rate, 
        f.rental_duration AS duration
    FROM public.film f 
    INNER JOIN public.inventory i ON f.film_id = i.film_id
    WHERE UPPER(f.title) LIKE '%CHOCOLATE%'
    LIMIT 1
),
renting_customer AS (
    SELECT c.customer_id AS customer
    FROM public.customer c 
    WHERE lower(c.first_name) = 'mary' AND lower(c.last_name) = 'smith' AND c.address_id = 5
),
rental_date AS (
    SELECT CAST('2017-01-02' AS date) AS rental_date
),  
staff_data AS (
    SELECT s.staff_id AS staff_id
    FROM public.staff s
    WHERE lower(s.username) = 'mike'
),
rental_insert AS (                                              
    INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
    SELECT 
        rd.rental_date,
        rm.inventory_id,
        rc.customer,
        rd.rental_date + (rm.duration * INTERVAL '1 week') AS return_date,
        sd.staff_id
    FROM renting_movies rm
    CROSS JOIN renting_customer rc
    CROSS JOIN rental_date rd
    CROSS JOIN staff_data sd
    RETURNING rental_id, return_date
),
rental_update AS (
    UPDATE public.rental
    SET return_date = current_date
   	WHERE rental_id = (SELECT max(r.rental_id)  FROM public.rental r)
    RETURNING public.rental.rental_id, public.rental.return_date
)
SELECT ru.rental_id, ru.return_date
FROM rental_update ru;
COMMIT;
/* 5. Revoke the "rental" group's INSERT permission for the "rental" table. Try to insert new rows into the "rental" table make sure this action is denied. 
 * This code checks if the rental group currently has the INSERT privilege on the rental table. 
 * If the privilege exists, it revokes the INSERT permission from the group and displays a message confirming that the privilege has been revoked.*/

DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.role_table_grants
        WHERE grantee = 'rental'
          AND table_name = 'rental'
          AND privilege_type = 'INSERT')

 	THEN
        REVOKE INSERT ON TABLE public.rental FROM GROUP rental;
        RAISE NOTICE 'INSERT privilege revoked from the rental group.';
    ELSE
        RAISE NOTICE 'INSERT privilege was already revoked from the rental group.';
    END IF;
END $$;

-- Testing the behaviour of the rental group after revoking the INSERT permission
SET ROLE rental;
SELECT current_user;
RESET ROLE;

WITH renting_movies AS (                                                    
    SELECT 
        f.film_id AS film_id, 
        i.inventory_id AS inventory_id, 
        f.rental_rate AS rate, 
        f.rental_duration AS duration
    FROM public.film f 
    INNER JOIN public.inventory i ON f.film_id = i.film_id
    WHERE UPPER(f.title) LIKE '%WATER%'
    LIMIT 1
),
renting_customer AS (
    SELECT c.customer_id AS customer
    FROM public.customer c 
    WHERE lower(c.first_name) = 'linda' AND lower(c.last_name) = 'williams' AND c.address_id = 7
),
rental_date AS (
    SELECT CAST('2017-01-01' AS date) AS rental_date
),  
staff_data AS (
    SELECT s.staff_id AS staff_id
    FROM public.staff s
    WHERE lower(s.username) = 'mike'
),
rental_insert AS (                                              
    INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
    SELECT 
        rd.rental_date,
        rm.inventory_id,
        rc.customer,
        rd.rental_date + (rm.duration * INTERVAL '1 week') AS return_date,
        sd.staff_id
    FROM renting_movies rm
    CROSS JOIN renting_customer rc
    CROSS JOIN rental_date rd
    CROSS JOIN staff_data sd
    RETURNING rental_id, return_date)
    SELECT ri.rental_id  FROM rental_insert ri;
    COMMIT;
   
 /* 2.6. Create a personalized role for any customer already existing in the dvd_rental database. The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). The customer's payment and rental history must not be empty.
  * This script creates roles for each customer using an anonymus DO block, where a role name is based on their first and last name. 
  * The string_agg() function is used to create and execute the commands for role creation.
  * I have also created a 2.6.2. version of this task, in order to include the customer_id to the role name. The idea behind this, is that if two customers share the same first and last name, their roles will still be unique by including their customer_id*/
   --2.6.1.solution
DO $$
DECLARE
    role_commands TEXT;
BEGIN
    SELECT
        string_agg(
            'CREATE ROLE ' || concat('client_', customers.first_name, '_', customers.last_name) || '; ' ||
            'GRANT USAGE ON SCHEMA public TO ' || concat('client_', customers.first_name, '_', customers.last_name) || '; ' ||
            'GRANT CONNECT ON DATABASE dvdrental TO ' || concat('client_', customers.first_name, '_', customers.last_name) || '; ' ||
            'GRANT SELECT ON TABLE public.payment TO ' || concat('client_', customers.first_name, '_', customers.last_name) || '; ' ||
            'GRANT SELECT ON TABLE public.customer TO ' || concat('client_', customers.first_name, '_', customers.last_name) || '; ' ||
            'GRANT SELECT ON TABLE public.rental TO ' || concat('client_', customers.first_name, '_', customers.last_name) || ';',
            ' ')
    INTO role_commands
    FROM (
        SELECT 
			DISTINCT c.first_name,
			c.last_name
        FROM public.customer c
        JOIN public.payment p ON c.customer_id = p.customer_id
        JOIN public.rental r ON c.customer_id = r.customer_id
        WHERE p.amount IS NOT NULL AND r.rental_id IS NOT NULL) as customers
    WHERE NOT EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = concat('client_', customers.first_name, '_', customers.last_name));
    IF role_commands IS NULL THEN
        RAISE NOTICE 'No new roles to create. All roles already exist.';
    ELSE
        EXECUTE role_commands;
    END IF;
END $$;

--2.6.2. solution with additional customer_id

DO $$
DECLARE
 role_commands TEXT;
BEGIN
    SELECT
        string_agg(
            'CREATE ROLE ' || concat('client_', customers.customer_id, '_', customers.first_name, '_', customers.last_name) || '; ' ||
            'GRANT USAGE ON SCHEMA public TO ' || concat('client_', customers.customer_id, '_', customers.first_name, '_', customers.last_name) || '; ' ||
            'GRANT CONNECT ON DATABASE dvdrental TO ' || concat('client_', customers.customer_id, '_', customers.first_name, '_', customers.last_name) || '; ' ||
            'GRANT SELECT ON TABLE public.payment TO ' || concat('client_', customers.customer_id, '_', customers.first_name, '_', customers.last_name) || '; ' ||
            'GRANT SELECT ON TABLE public.customer TO ' || concat('client_', customers.customer_id, '_', customers.first_name, '_', customers.last_name) || '; ' ||
            'GRANT SELECT ON TABLE public.rental TO ' || concat('client_', customers.customer_id, '_', customers.first_name, '_', customers.last_name) || ';',
            ' ')
    INTO role_commands
    FROM (
        SELECT 
				c.customer_id, 
				c.first_name,
				c.last_name
        FROM public.customer c
        JOIN public.payment p ON c.customer_id = p.customer_id
        JOIN public.rental r ON c.customer_id = r.customer_id
        WHERE p.amount IS NOT NULL AND r.rental_id IS NOT NULL) as customers
   WHERE NOT EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = concat('client_', customers.customer_id, '_', customers.first_name, '_', customers.last_name));
    IF role_commands IS NULL THEN
        RAISE NOTICE 'No new roles to create. All roles already exist.';
    ELSE
        EXECUTE role_commands;
    END IF;
END $$;


/*3.Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. Write a query to make sure this user sees only their own data.
 * This code enables row level security on the rental and payment tables. It creates a policiy where users can only see their own records based on their first and last name ( how the client roles were setup in the previous task)
 * The lower() function ensures the comparison is not case-sensitive. The access to the tables were given in the previous task were the client roles were created*/

ALTER TABLE public.rental ENABLE ROW LEVEL SECURITY;
--ALTER TABLE public.rental DISABLE ROW LEVEL SECURITY;
CREATE POLICY rental_rls ON public.rental FOR SELECT USING (current_user =lower( (SELECT ('client_'|| c.first_name || '_' || c.last_name) FROM customer c WHERE c.customer_id = rental.customer_id)));
--DROP POLICY rental_rls ON public.rental; 


ALTER TABLE public.payment ENABLE ROW LEVEL SECURITY;
--ALTER TABLE public.payment DISABLE ROW LEVEL SECURITY;
CREATE POLICY payment_rls ON public.payment FOR SELECT USING (current_user = lower((SELECT ('client_'|| c.first_name || '_' || c.last_name) FROM customer c WHERE c.customer_id = payment.customer_id)));
--DROP POLICY payment_rls ON public.payment; 
 
--Checking the RLS policies using client_aaron_selby (customer_id 375)
SET ROLE client_aaron_selby;   
SELECT current_user;
RESET ROLE;

SELECT * FROM film f;			-- The client don't have permission for the film table
SELECT * FROM rental r;			-- The client should only see the customer records with the customer_id 375 in the rental table
SELECT * FROM payment p ;		-- The client should only see the customer records with the customer_id 375 in the payment table