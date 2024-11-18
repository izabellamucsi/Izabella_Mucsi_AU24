/* Utilizing the returning fuction in the first iteration I solved the first three tasks in one step for each of the favorite movie and I inserted the Rush, Senna and Drive to Survive as favorite movies.
 * This first iteration uses CTEs and the returning clause to pass each of the favorite movies along with the actors into the `film`, `actor`, and `film_actor` tables if they don't already exist. 
 * Below this iteration, I also solved the first three task in seperate queries.
/* 1.1 Choose your top-3 favorite movies and add them to the 'film' table  */
/* 1.2 Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively. */
/* 1.3 Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).  */ */

--first favorite movie 

WITH defined_rental_specification AS (
SELECT 4.99 AS rental_rate,
1 AS rental_duration ),
	first_favorite_movie AS (                                     -- Defining the movie details
    SELECT 
    'RUSH' AS title,
     'A biographical sports drama film about the rivalry between Formula One drivers Niki Lauda and James Hunt' AS description,
     2013 AS release_year,
     123 AS "length",
     19.99 AS replacement_cost,
      now() AS last_update ),
      	language_data as(
      	SELECT l.language_id AS language_id
      	FROM public."language" l
      	WHERE lower(l.name) = 'english'),
      		original_language_data AS (
      		SELECT l.language_id AS  original_language_id
      		FROM public."language" l 
      		WHERE lower(l.name) = 'english'),
      			rating_data AS (
      			SELECT f.rating
      			FROM public.film f
      			WHERE f.film_id = 8),
		insert_first_movie AS (																			-- Inserting the movie if it doesn't already exist in the `film` table
 		INSERT INTO public.film (title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update)
    	SELECT 
        ffm.title,
        ffm.description,
        ffm.release_year,
        ld.language_id,
        old.original_language_id,
        drs.rental_duration,     -- Using rental duration from defined rental specification
        drs.rental_rate,         -- Using rental rate from defined rental specification
        ffm.length,
        ffm.replacement_cost,
        rd.rating,
        ffm.last_update
    	FROM first_favorite_movie ffm
    	CROSS JOIN defined_rental_specification drs  -- Joining rental specification
    	CROSS JOIN language_data ld					 -- Joining language data 
    	CROSS JOIN rating_data rd					 -- Joining rating Data
    	CROSS JOIN original_language_data OLD		 -- Joining original language data
    	WHERE NOT EXISTS (
        SELECT * 
        FROM public.film f 
        WHERE f.title = ffm.title)
    	RETURNING film_id ),
		    actors_first_movie AS (
   			SELECT 
        	'CHRIS' AS first_name, 
       		'HEMSWORTH' AS last_name                -- Defining the two lead actors
   			 UNION ALL
    		SELECT 
        	'DANIEL' AS first_name, 
        	'BRÜHL' AS last_name),
				insert_actor AS (                    -- Inserting each actor into the actor table
				INSERT INTO public.actor (first_name, last_name)
				SELECT 
				afm.first_name, 
				afm.last_name
				FROM actors_first_movie afm
				WHERE NOT EXISTS (
				      			SELECT * 
				        		FROM public.actor a 
				        		WHERE a.first_name = afm.first_name AND a.last_name = afm.last_name)
				    			RETURNING actor_id, first_name, last_name)
				    					INSERT INTO public.film_actor (film_id, actor_id)				-- Inserting into film_actor table
										SELECT 
										    ifm.film_id, 
										    ia.actor_id
										FROM insert_first_movie ifm
										CROSS JOIN insert_actor ia
										RETURNING film_id, actor_id;
										COMMIT;
--second favorite movie 

WITH defined_rental_specification AS (
SELECT 9.99 AS rental_rate,
2 AS rental_duration ),
	first_favorite_movie AS (                                     -- Defining the movie details
    SELECT 
    'SENNA' 			  AS title,
     'A documentary film about the life and career of Brazilian Formula One racing driver Ayrton Senna' AS description,
     2010 				  AS release_year,
	 106 				  AS "length",
	 19.99 				  AS replacement_cost,
	 now() 				  AS last_update),
	 	language_data as(
      	SELECT l.language_id AS language_id
      	FROM public."language" l
      	WHERE lower(l.name) = 'english'),
      		original_language_data AS (
      		SELECT l.language_id AS  original_language_id
      		FROM public."language" l 
      		WHERE lower(l.name) = 'english'),
      			rating_data AS (
      			SELECT f.rating
      			FROM public.film f
      			WHERE f.film_id = 7),
		insert_first_movie AS (																			-- Inserting the movie if it doesn't already exist in the `film` table
 		INSERT INTO public.film (title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update)
    	SELECT 
        ffm.title,
        ffm.description,
        ffm.release_year,
        ld.language_id,
        old.original_language_id, 
        drs.rental_duration,      
        drs.rental_rate,         
        ffm.length,
        ffm.replacement_cost,
        rd.rating,
        ffm.last_update
    	FROM first_favorite_movie ffm
    	CROSS JOIN defined_rental_specification drs  -- Joining rental specification
    	CROSS JOIN language_data ld					 -- Joining language data 
    	CROSS JOIN rating_data rd					 -- Joining rating Data
    	CROSS JOIN original_language_data OLD		 -- Joining original language data
    	WHERE NOT EXISTS (
        SELECT * 
        FROM public.film f 
        WHERE f.title = ffm.title)
    	RETURNING film_id ),
		    actors_first_movie AS (
   			SELECT 
        	'AYRTON' AS first_name, 
       		'SENNA' AS last_name                -- Defining the two lead actors
   			 UNION ALL
    		SELECT 
        	'ALAIN' AS first_name, 
        	'PROST' AS last_name),
				insert_actor AS (                    -- Inserting each actor into the actor table
				INSERT INTO public.actor (first_name, last_name)
				SELECT 
				afm.first_name, 
				afm.last_name
				FROM actors_first_movie afm
				WHERE NOT EXISTS (
				      			SELECT * 
				        		FROM public.actor a 
				        		WHERE a.first_name = afm.first_name AND a.last_name = afm.last_name)
				    			RETURNING actor_id, first_name, last_name)
				    					INSERT INTO public.film_actor (film_id, actor_id)				-- Inserting into film_actor table
										SELECT 
										    ifm.film_id, 
										    ia.actor_id
										FROM insert_first_movie ifm
										CROSS JOIN insert_actor ia
										RETURNING film_id, actor_id;
										COMMIT;
--third favorite movie 

WITH defined_rental_specification AS (
SELECT 19.99 AS rental_rate,
3 AS rental_duration ),
	first_favorite_movie AS (                                     -- Defining the movie details
    SELECT 
    'DRIVE TO SURVIVE'  AS title,
	 'A documentary that follows Formula One teams and drivers during a Formula One season' AS description,
	 2019 			    AS release_year,
	 45 				AS "length",
	 19.99 			    AS replacement_cost,
	 now() AS last_update),
	 	language_data as(
      	SELECT l.language_id AS language_id
      	FROM public."language" l
      	WHERE lower(l.name) = 'english'),
      		original_language_data AS (
      		SELECT l.language_id AS  original_language_id
      		FROM public."language" l 
      		WHERE lower(l.name) = 'english'),
      			rating_data AS (
      			SELECT f.rating
      			FROM public.film f
      			WHERE f.film_id = 2),
		insert_first_movie AS (																			-- Inserting the movie if it doesn't already exist in the `film` table
 		INSERT INTO public.film (title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update)
    	SELECT 
        ffm.title,
        ffm.description,
        ffm.release_year,
        ld.language_id,
        old.original_language_id,
        drs.rental_duration,     
        drs.rental_rate,         
        ffm.length,
        ffm.replacement_cost,
        rd.rating,
        ffm.last_update
    	FROM first_favorite_movie ffm
    	CROSS JOIN defined_rental_specification drs  -- Joining rental specification
    	CROSS JOIN language_data ld					 -- Joining language data 
    	CROSS JOIN rating_data rd					 -- Joining rating Data
    	CROSS JOIN original_language_data OLD		 -- Joining original language data
    	WHERE NOT EXISTS (
        SELECT * 
        FROM public.film f 
        WHERE f.title = ffm.title)
    	RETURNING film_id ),
		    actors_first_movie AS (
   			SELECT 
        	'LEWIS' AS first_name, 
       		'HAMILTON' AS last_name                -- Defining the two lead actors
   			 UNION ALL
    		SELECT 
        	'MAX' AS first_name, 
        	'VERSTAPPEN' AS last_name),
				insert_actor AS (                    -- Inserting each actor into the actor table
				INSERT INTO public.actor (first_name, last_name)
				SELECT 
				afm.first_name, 
				afm.last_name
				FROM actors_first_movie afm
				WHERE NOT EXISTS (
				      			SELECT * 
				        		FROM public.actor a 
				        		WHERE a.first_name = afm.first_name AND a.last_name = afm.last_name)
				    			RETURNING actor_id, first_name, last_name)
				    					INSERT INTO public.film_actor (film_id, actor_id)				-- Inserting into film_actor table
										SELECT 
										    ifm.film_id, 
										    ia.actor_id
										FROM insert_first_movie ifm
										CROSS JOIN insert_actor ia
										RETURNING film_id, actor_id;
										COMMIT;


/* 1.1b -  Choose your top-3 favorite movies and add them to the 'film' table (films with the title Film1, Film2, etc - will not be taken into account and grade will be reduced) */

WITH favorite_movies AS (				--Defining the movie details of the three favorite movies
SELECT 
'RUSH' 				AS title,
'A biographical sports drama film about the rivalry between Formula One drivers Niki Lauda and James Hunt' AS description,
2013 				AS release_year,
(SELECT l.language_id FROM public."language" l WHERE lower(l.name) = 'english') AS language_id,
(SELECT l.language_id FROM public."language" l WHERE lower(l.name) = 'english') AS original_language_id,
3 					AS rental_duration,
4.99 				AS rental_rate,
123 				AS "length",
19.99 				AS replacement_cost,
(SELECT f.rating FROM public.film f WHERE f.film_id = 8) AS rating,
now() 			 	AS last_update
UNION ALL
SELECT 
'SENNA' 				AS title,
'A documentary film about the life and career of Brazilian Formula One racing driver Ayrton Senna' AS description,
2010 					AS release_year,
(SELECT l.language_id FROM public."language" l WHERE lower(l.name) = 'english') AS language_id,
(SELECT l.language_id FROM public."language" l WHERE lower(l.name) = 'english') AS original_language_id,
3 						AS rental_duration,
3.99 					AS rental_rate,
106 					AS "length",
19.99 					AS replacement_cost,
(SELECT f.rating FROM public.film f WHERE f.film_id = 7) AS rating,
now() 					AS last_update
UNION ALL
SELECT 
'DRIVE TO SURVIVE' 	AS title,
'A documentary that follows Formula One teams and drivers during a Formula One season' AS description,
2019 				AS release_year,
(SELECT l.language_id FROM public."language" l WHERE lower(l.name) = 'english') AS language_id,
(SELECT l.language_id FROM public."language" l WHERE lower(l.name) = 'english') AS original_language_id,
3 					AS rental_duration,
2.99 				AS rental_rate,
45 					AS "length",
19.99 				AS replacement_cost,
(SELECT f.rating FROM public.film f WHERE f.film_id = 2) AS rating,
now() 				AS last_update),
	inserted_movies AS (
	INSERT INTO film (title,description,release_year,language_id,original_language_id,rental_duration,rental_rate,length,replacement_cost,rating,last_update) --Inserting the movies into the film table
	SELECT *
	FROM favorite_movies fm
	WHERE NOT EXISTS (
	SELECT f.title
	FROM public.film f
	WHERE f.title = fm.title)
	RETURNING film_id)
	SELECT * FROM inserted_movies;
	COMMIT;

/*1.2 b - Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.*/

UPDATE public.film						 --Updating the rental data for the inserted favorite films
SET 
   rental_rate = CASE
       WHEN upper(title) = 'RUSH' THEN 4.99
       WHEN upper(title) = 'SENNA' THEN 9.99
       WHEN upper(title) = 'DRIVE TO SURVIVE' THEN 12.99    
   END,
   rental_duration = CASE
       WHEN upper(title) = 'RUSH' THEN 1
       WHEN upper(title) = 'SENNA' THEN 2
       WHEN upper(title) = 'DRIVE TO SURVIVE' THEN 3
   END
WHERE upper(title) IN ('RUSH', 'SENNA', 'DRIVE TO SURVIVE')
RETURNING rental_rate, rental_duration;

COMMIT;
   


/* 1.3b - Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total). */

WITH new_actors AS (										--Defining the new actors 
SELECT 'CHRIS' AS first_name, 'HEMSWORTH' AS last_name
UNION ALL
SELECT 'DANIEL' AS first_name, 'BRÜHL' AS last_name
UNION ALL
SELECT 'LEWIS' AS first_name, 'HAMILTON' AS last_name
UNION ALL
SELECT 'MAX' AS first_name, 'VERSTAPPEN' AS last_name
UNION ALL
SELECT 'AYRTON' AS first_name, 'SENNA' AS last_name
UNION ALL
SELECT 'ALAIN' AS first_name, 'PROST' AS last_name
),
	inserted_actors AS (										--Inserting the new actors into the actor table
	INSERT INTO public.actor (first_name, last_name)
	SELECT 
	na.first_name, 
	na.last_name
	FROM new_actors na
	WHERE NOT EXISTS (
	SELECT * 
	FROM public.actor a 
	WHERE a.first_name = na.first_name AND a.last_name = na.last_name)
    RETURNING actor_id, first_name, last_name, last_name AS actor_last_name
	),
		film_ids AS (                                                -- Matching actors to their respective films
		SELECT 
		ia.actor_id,
		CASE 
		WHEN UPPER(ia.actor_last_name) IN ('HEMSWORTH', 'BRÜHL') THEN (SELECT f.film_id FROM film f WHERE UPPER(f.title) = 'RUSH')
	    WHEN UPPER(ia.actor_last_name) IN ('HAMILTON', 'VERSTAPPEN') THEN (SELECT f.film_id FROM film f WHERE UPPER(f.title) = 'DRIVE TO SURVIVE')
		WHEN UPPER(ia.actor_last_name) IN ('SENNA', 'PROST') THEN (SELECT f.film_id FROM film f WHERE UPPER(f.title) = 'SENNA')
        ELSE NULL
		END AS film_id
		FROM inserted_actors ia)
			INSERT INTO public.film_actor (actor_id, film_id)
			SELECT 
			actor_id, 
			film_id
			FROM film_ids
			WHERE film_id IS NOT NULL; 
			COMMIT;

	
/* 1.4 Add your favorite movies to any store's inventory 
 * In the following query I have added the favorite movies to the inventory table using CTE*/
 
WITH inserted_movies AS (									--Selecting the movies that will be added to the inventory table
SELECT 
f.film_id AS movie_id
FROM public.film f 
WHERE UPPER(f.title) IN ('RUSH', 'SENNA','DRIVE TO SURVIVE')),
	chosen_store AS (
	 SELECT s.store_id AS store_id
	 FROM public.staff s
	 WHERE s.staff_id = 1
	 LIMIT 1),
	insert_inventory AS (
	INSERT INTO public.inventory (film_id, store_id, last_update)								--Inserting the selected movies into the inventory table
	SELECT 
	im.movie_id,
	cs.store_id,
	current_date
	FROM inserted_movies im
	CROSS JOIN chosen_store cs
	RETURNING inventory_id)
	SELECT * FROM insert_inventory; 
	COMMIT;
/* 1.5 Alter any existing customer in the database with at least 43 rental and 43 payment records. Change their personal data to yours (first name, last name, address, etc.). 
 * I the next query I have found an existing customer with at least 43 rentals and payments in the table chosen_customer with the customer_id 401 and then updated their personal information with my details.*/

WITH chosen_customer AS (						-- selecting the customer with at least 43 rental and 43 payment records
SELECT 
c.customer_id AS customer,
COUNT(p.payment_id) AS paym_records, 
COUNT(r.rental_id) AS rent_records 
FROM public.customer c
INNER JOIN public.payment p ON p.customer_id = c.customer_id 
INNER JOIN public.rental r ON p.rental_id = r.rental_id  
GROUP BY c.customer_id
HAVING COUNT(p.payment_id) = 43 AND COUNT(r.rental_id) = 43
LIMIT 1),
		updated_customer AS (																			-- Updating the personal data of the selected customer
		UPDATE public.customer 
		SET 		
		store_id= 
				(SELECT s.store_id AS store_id
	 			FROM public.staff s
	 			WHERE s.staff_id = 1
	 			LIMIT 1),
		first_name='Izabella', 
		last_name='Mucsi', 
		email='izabellamucsi@gmail.com',
		address_id=(
					SELECT a.address_id
					FROM public.address a 
					WHERE a.city_id = 1
					LIMIT 1),
						activebool=true, 
						create_date='now'::text::date, 
						last_update=now(), 
						active=1
						WHERE customer_id = (
											SELECT cc.customer
											FROM chosen_customer cc)
											RETURNING customer_id)
											SELECT * FROM updated_customer;
											COMMIT;


/* 1.6 Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'
 * This query deletes all rental and payment records related to the specified customer from the previous task with at least 43 rental and 43 payment records.*/ 

WITH payment_delete AS (											--Deleting the payment related records of the specific customer bases on the customer's name
DELETE FROM public.payment p
WHERE p.payment_id IN (
						SELECT p.payment_id 
						FROM public.payment p 
WHERE  customer_id = (
						SELECT customer_id
						FROM public.customer c
WHERE LOWER(c.first_name) = 'izabella' AND LOWER(last_name) = 'mucsi'))
),
	rental_delete AS (													--Deleting the rental related records of the specific customer bases on the customer's name
	DELETE FROM public.rental r 
	WHERE r.rental_id IN (
						SELECT r.rental_id 
						FROM public.rental r 
	WHERE  customer_id = (
						SELECT customer_id
						FROM public.customer c
	WHERE LOWER(c.first_name) = 'izabella' AND LOWER(last_name) = 'mucsi'))
	RETURNING rental_id)
	SELECT * FROM rental_delete;
	COMMIT;
 
/* 1.7 Rent your favorite movies from the store they are in and pay for them (add corresponding records to the database to represent this activity)
 * In the following query the previously specified customer will rent out the three favorite movies from the first tak by inserting the appropriate records 
 * to the rental (via the rental_insert) and to the payment (via payment_insert) table assuming that the customer paid on the day of the rental and the rental duration is in weeks.. */

WITH renting_movies AS (													-- Selecting the favorite movies 
SELECT 
f.film_id AS film_id, 
i.inventory_id AS inventory_id, 
f.rental_rate AS rate, 
f.rental_duration AS duration
FROM public.film f 
INNER JOIN public.inventory i ON f.film_id = i.film_id
WHERE UPPER(f.title) IN ('SENNA', 'RUSH','DRIVE TO SURVIVE')
),
	renting_customer AS (													-- Selecting the customer ID based on the customer's name
    SELECT c.customer_id AS customer
    FROM public.customer c 
    WHERE LOWER(c.first_name) = 'izabella' AND LOWER(last_name) = 'mucsi'
),
		rental_date AS (
		SELECT CAST('2017-01-01' AS date) AS rental_date
		),	
			staff_data AS (
			SELECT s.staff_id AS staff_id
			FROM public.staff s
			WHERE lower(s.username) = 'mike'),
				rental_insert AS (												-- Inserting the rental records for each movie 
				INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
				SELECT 
				rd.rental_date,
				rm.inventory_id,
				rc.customer,
				rd.rental_date + (rm.duration * INTERVAL '1 week') AS return_date,
				sd.staff_id,
				now() AS last_update
				FROM renting_movies rm
				CROSS JOIN renting_customer rc
				CROSS JOIN rental_date rd
				CROSS JOIN staff_data sd
				RETURNING rental_id, inventory_id),
					payment_insert AS (													-- Inserting the payment records for each rental 
					INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
					SELECT 
					rc.customer,
					sd.staff_id,
					ri.rental_id,
					rm.rate * rm.duration AS amount,
					rd.rental_date 
					FROM rental_insert ri
					CROSS JOIN renting_customer rc
					CROSS JOIN rental_date rd
					CROSS JOIN staff_data sd
					INNER JOIN renting_movies rm ON rm.inventory_id = ri.inventory_id
					RETURNING payment_id)
	 				SELECT * FROM payment_insert,rental_insert;
	 				COMMIT;

	 			