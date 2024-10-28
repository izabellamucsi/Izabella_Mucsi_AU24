/* PART 1.1 - This code finds the animation movies between 2017 to 2019 with a rental rate above 1 and sorts them alphabetically by title.
I used a subquery to check if the movie belongs to the 'Animation' category*/

SELECT f.film_id,
		f.title,
		f.release_year
FROM film f 
WHERE release_year  BETWEEN 2017 AND 2019
								 AND f.rental_rate >1
								 AND film_id IN (SELECT fc.film_id
												FROM film_category fc 
												WHERE fc.category_id = 
													 (SELECT category_id           -- Selects only films categorized as Animation
													  FROM category c 
													  WHERE c.name = 'Animation'))
								
ORDER BY f.title ASC;


/* PART 1.2 - This query calculates total revenue for each store since March 2017 until the current date and also shows the combined address and address2 together with the revenue.
I used CONCAT to merge address and address2.*/

SELECT  concat(a.address,a.address2)  AS store_adress, 
						sum(p.amount) AS revenue 
FROM payment p 
LEFT JOIN rental r ON r.rental_id = p.rental_id 
LEFT JOIN inventory i ON i.inventory_id = r.inventory_id 
LEFT JOIN store s ON s.store_id = i.store_id 
LEFT JOIN address a ON a.address_id = s.address_id 
WHERE p.payment_date BETWEEN '2017-03-01' AND  current_date -- Filters payments from March 1, 2017 to the current date.
GROUP BY i.store_id,a.address,a.address2;


/* PART 1.3 - This code finds the top 5 actors by the number of movies they've appeared in since 2015, ordering by movie count in descending order.
 * I used limit 5 to ensure that only the top 5 actors are returned */

SELECT a.first_name,
		a.last_name , 
		count(fa.film_id)  AS number_of_movies  
 FROM film_actor fa
 LEFT JOIN actor a ON fa.actor_id =a.actor_id 
 LEFT JOIN film f ON f.film_id = fa.film_id 
 WHERE f.release_year BETWEEN 2015 AND EXTRACT (YEAR FROM current_date)
 GROUP BY a.first_name, a.last_name
 ORDER BY number_of_movies DESC
 LIMIT 5;
 
/* PART 1.4 - This query counts the number of 'Drama,' 'Travel,' and 'Documentary' movies per year.
 * I used CTE tables to solve the task. At first the query identifies the unique release years, then it calculates the number of rentals for each film category per year (travel, drama, documentary)
 *  and finally the last select statement combines these tables. By using the coalesce function it converted the NULL values into 0 in the result table. */

WITH release_years as(                                         --Creating a list of distinct release years
SELECT DISTINCT f.release_year AS years
FROM film f
ORDER BY f.release_year DESC),
	number_of_drama_movies AS (									--Counting the number of drama movies released each year
	SELECT f.release_year,
			COUNT(f.film_id) AS number_of_drama_rental
	FROM film f 
	LEFT JOIN film_category fc ON fc.film_id = f.film_id	
	LEFT JOIN category c ON c.category_id = fc.category_id
	WHERE c.name = 'Drama'
	GROUP BY f.release_year 	
	ORDER BY f.release_year),
		number_of_travel_movies AS (
		SELECT f.release_year,									--Counting the number of travel movies released each year
				COUNT(f.film_id) AS number_of_travel_rental
		FROM film f 
		LEFT JOIN film_category fc ON fc.film_id = f.film_id	
		LEFT JOIN category c ON c.category_id = fc.category_id
		WHERE c.name = 'Travel'
		GROUP BY f.release_year 	
		ORDER BY f.release_year),
			number_of_documentary_movies AS (					--Counting the number of documentary movies released each year
			SELECT f.release_year,
					COUNT(f.film_id) AS number_of_documentary_rental
			FROM film f 
			LEFT JOIN film_category fc ON fc.film_id = f.film_id	
			LEFT JOIN category c ON c.category_id = fc.category_id
			WHERE c.name = 'Documentary'
			GROUP BY f.release_year 	
			ORDER BY f.release_year)
				SELECT r.years,									--Combining the release years with the counts of each movie genre,
						COALESCE(t.number_of_travel_rental,0) AS number_of_travel_movies,
						COALESCE(d.number_of_drama_rental,0) AS number_of_drama_movies,
						COALESCE(d2.number_of_documentary_rental,0) AS number_of_documentary_movies
				FROM release_years r 
				LEFT JOIN number_of_drama_movies d  ON d.release_year = r.years
				LEFT JOIN number_of_travel_movies t ON t.release_year = r.years
				LEFT JOIN number_of_documentary_movies d2 ON d2.release_year = r.years
				GROUP BY r.years,t.number_of_travel_rental, d.number_of_drama_rental,d2.number_of_documentary_rental
				ORDER BY r.years desc;


/* PART 1.5 - This query lists all horror films, each client has rented with film titles combined into a single column and the total amount paid for these rentals.
I used STRING_AGG to display the list of horror movies in one column, separated by commas.*/

SELECT  c.customer_id,
		c.first_name || ' ' || c.last_name AS client_name,
		string_agg( DISTINCT f.title,', ') AS Title, 		-- Combines all rented horror movie titles
		sum(p.amount) AS rent_paid
FROM customer c 
INNER JOIN payment p ON p.customer_id  = c.customer_id 
INNER  JOIN rental r ON p.rental_id = r.rental_id 
INNER  JOIN inventory i ON i.inventory_id = r.inventory_id 
INNER  JOIN film f ON f.film_id = i.film_id 
INNER  JOIN film_category fc ON fc.film_id = f.film_id 
INNER  JOIN category c2 ON c2.category_id = fc.category_id 
WHERE  fc.category_id = (
							SELECT c3.category_id
							FROM category c3 
							WHERE c3.name = 'Horror')
GROUP BY c.customer_id,c.first_name, c.last_name
ORDER BY sum(p.amount) DESC;


/* PART 2.1 - I used CTE called the_last_one to determine the latest store each staff member had worked in based on the maximum payment_date in 2017.
 * In the next step, in the select statement I calculated the total revenue generated by each staff member in 2017 and the result is ordered by the revenue column and limited to the top 3 employee.*/

WITH the_last_one AS (                     -- Finding the last store for each employee
SELECT s.staff_id, 
		s.store_id,
		max(p.payment_date) AS Last_date
FROM staff s 
LEFT JOIN payment p ON p.staff_id = s.staff_id 
WHERE EXTRACT(YEAR FROM p.payment_date) = 2017 
GROUP BY s.store_id,s.staff_id)
	SELECT s.first_name,
			s.last_name,
			s.staff_id,
			s.store_id, 
			sum(p.amount) AS revenue
	FROM staff s 
	LEFT JOIN payment p ON p.staff_id = s.staff_id 
	WHERE EXTRACT(YEAR FROM p.payment_date) = 2017 AND s.store_id IN (
																		SELECT s.store_id
																		FROM the_last_one)
													AND s.staff_id IN (SELECT s.staff_id
																		FROM the_last_one)
	GROUP BY s.first_name,s.last_name,s.staff_id
	ORDER BY sum(p.amount) DESC 
	LIMIT 3;

/* PART 2.2  - I used common table expressions in order to connect multiple tables that were necessary to solve this task. 
 * First, I calculated the total number of rentals for each movie in order to identify the top five highest rental numbers which then was linked back to the movies in orer to find the items with rental counts equal to the already calculated top five highest rental counts.
 * Using the Motion Picture Association film rating system and the CASE statement I added the expected age of the audience*/

WITH count_rental AS (SELECT count(r.rental_id) AS number_of_rentals  -- Count the number of rentals for each film 
FROM rental r 
LEFT JOIN inventory i ON i.inventory_id = r.inventory_id 
LEFT JOIN film f  ON i.film_id = f.film_id 
GROUP BY f.film_id 
ORDER BY number_of_rentals DESC),
		top_five_rental AS (                                          -- Select the top 5 rental counts
		SELECT DISTINCT cr.number_of_rentals AS ordered_rental_numbers
		FROM count_rental cr
		ORDER BY ordered_rental_numbers DESC
		LIMIT 5)
			SELECT f.film_id,
					f.title,
					f.rating,
					count(r.rental_id) AS rental_count,   
			CASE 
	        WHEN f.rating = 'R' THEN 'Under 17 requires parental guidance'
	        WHEN f.rating = 'NC-17' THEN 'Inappropriate for children under 17'
	        WHEN f.rating = 'PG-13' THEN 'Inappropriate for children under 13'
	        WHEN f.rating = 'PG' THEN 'All ages with parental guidance'
	        WHEN f.rating = 'G' THEN 'All ages'
	        ELSE 'No rating category'
    		END AS audience_age
			FROM rental r 
			LEFT JOIN inventory i ON i.inventory_id = r.inventory_id 
			LEFT JOIN film f  ON i.film_id = f.film_id
			GROUP BY f.film_id 
			HAVING count(r.rental_id) IN ( SELECT * FROM top_five_rental)
			ORDER BY rental_count DESC;
			
		
/* PART 3.1 - V1 interpretation -  The query calculates the gap in years, between the current year and each actor’s latest film release year,
	 * then the result is ordered by the longest gaps to identify those actors/actresses who haven’t acted for a while. */
		
SELECT a.actor_id,
		a.first_name || ' ' || a.last_name AS actor_name,
		extract(YEAR FROM current_date) - MAX(f.release_year) AS gap_to_current_year -- Calculating the gap by subtracting the most recent release year from the current year
FROM actor a 
LEFT JOIN film_actor fa ON a.actor_id = fa.actor_id 
LEFT JOIN film f ON f.film_id = fa.film_id 
GROUP BY  a.actor_id, a.first_name, a.last_name
ORDER BY gap_to_current_year DESC, actor_name;
		
/* PART 3.2 - V2 interpretation - to calculate the largest gap between sequential films for each actor I used CTE. 
 * Defined two identical tables (table_1 and table_2) with release years for each actor's movies and joined them in order to calculate the gaps between the sequential movies and to find the max gap for each actor
 * In the gap_year table, table_1 and table_2 was joined on the condition that the release years of table_2 should be greater than the release years of from table_1 in order to ensure that the years in the second table will correspond to a later movie).
 *In the last step, the gap between two consecutive movies for each actor was calculated as year_2 - year_1. By using the MAX function the query will show the max gap between sequential films for every actor */


WITH table_1 AS (                                   --Listing each film's release year and actor_id for the self-join
SELECT f.release_year, 
		a.actor_id 
FROM film f 
INNER JOIN film_actor fa ON fa.film_id = f.film_id 
INNER JOIN actor a ON a.actor_id = fa.actor_id 
ORDER BY f.release_year  DESC),
	table_2 AS (                                        --List each film's release year and actor_id for the self-join
	SELECT f.release_year,
			a.actor_id 
	FROM film f 
	INNER JOIN film_actor fa ON fa.film_id = f.film_id 
	INNER JOIN actor a ON a.actor_id = fa.actor_id 
	ORDER BY f.release_year  DESC),
		gap_year AS (                                                                                       
    	SELECT 	t1.release_year AS year_1,
    			min(t2.release_year) AS year_2,
    			t1.actor_id AS actor       --Calculating the gap between the release years
    	FROM table_1 t1
 		LEFT JOIN table_2 t2 ON t2.release_year > t1.release_year AND t1.actor_id = t2.actor_id
 		GROUP BY t1.release_year,t1.actor_id
 		ORDER BY t1.release_year)
 			SELECT gy.actor, 
 					a.first_name || ' ' || a.last_name AS actor_name, 
 					max(COALESCE ((gy.year_2 - gy.year_1),0)) AS max_gap   --Selecting the maximum gap for each actor
 			FROM gap_year gy
 			LEFT JOIN actor	a ON a.actor_id = gy.actor
 			GROUP BY gy.actor, a.first_name, a.last_name
 			ORDER BY max_gap DESC;