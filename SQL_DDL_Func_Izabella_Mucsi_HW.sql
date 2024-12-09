/* Task 1. The view calculates the sales revenue as a sum of the values from the amount column of the payment table by linking it to the inventory, rental, film and film categories tables.
 * The current_date ensures that the current quarter is dynamic which is calculated by finding the start of the current quarter and addig a 3month interval.
   The having clause ensures that only categories with the revenue greater than zero are included in the view.
   The most recent payment_date in the payment table was on the 31st of May in 2017, therefore the the view for the current quarter will be empty.*/

DROP VIEW IF EXISTS sales_revenue_by_category_qtr;
CREATE OR REPLACE  VIEW sales_revenue_by_category_qtr AS
SELECT 
c.category_id,
c.name,
sum(p.amount) AS sales_revenue
FROM public.payment p 
INNER JOIN public.rental r ON p.rental_id = r.rental_id
INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
INNER JOIN public.film_category fc ON i.film_id = fc.film_id
INNER JOIN public.category c ON fc.category_id = c.category_id
WHERE EXTRACT (YEAR FROM p.payment_date) = EXTRACT (YEAR FROM current_date) 				
  AND EXTRACT (quarter FROM p.payment_date) = EXTRACT (quarter FROM current_date)
GROUP BY c.category_id
HAVING SUM(p.amount) > 0
ORDER BY sales_revenue DESC;

--Checking the result of the view
SELECT * FROM public.sales_revenue_by_category_qtr;

/* Task 2. The function calculates the sales revenue for each film category during a specific quarter and year provided in the input parameters.
 * The WHERE clause filters the payments by the specified quarter and year.
   If the query doesn't find any rows then the raise notice indicates that there are no revenues for the selected period otherwise it will return the results. */

DROP function IF EXISTS sales_revenue_by_category_qtr;
CREATE OR REPLACE FUNCTION sales_revenue_by_category_qtr(year_quarter INT)
RETURNS TABLE (
category TEXT,
revenue NUMERIC)
AS $$
BEGIN
RETURN QUERY
SELECT 
c.name AS category_name,											--Calculating the sales revenue by category in line with the input arguments
SUM(p.amount) AS sales_revenue
FROM public.payment p
LEFT JOIN public.rental r ON p.rental_id = r.rental_id
LEFT JOIN public.inventory i ON r.inventory_id = i.inventory_id
LEFT JOIN public.film_category fc ON i.film_id = fc.film_id
LEFT JOIN public.category c ON fc.category_id = c.category_id
WHERE
concat (EXTRACT(YEAR FROM p.payment_date),extract(QUARTER FROM p.payment_date))::integer = year_quarter
GROUP BY  c.category_id;
IF FOUND 
THEN
RETURN;
ELSE
RAISE NOTICE 'No reveneue found for the selected quarter and year';		--Message if no rows match the input criteria
END IF;
END;
$$ LANGUAGE plpgsql;

--Checking the result of the function
SELECT * FROM public.sales_revenue_by_category_qtr (20172);


/* Task 3. This function calculates the number of film rentals as an indicator of the movie popularity for each country.
 *The most_popular_film cte identifies the highest rental count (max_popularity) for each country which is defined as a input parameter.
 *If the query returns without any result a raise notice message will be dispalyed */

DROP FUNCTION IF EXISTS most_popular_films_by_countries(IN country_names TEXT[]);
CREATE OR REPLACE FUNCTION most_popular_films_by_countries (IN country_names TEXT[])
RETURNS TABLE (																			--Defining the returned table
country_name text,
film text,
rating mpaa_rating,
"language" character,
"length" smallint,
release_year year,
film_popularity bigint)
AS $$
BEGIN
RETURN query
WITH popular_films_by_countries AS (									
SELECT 
c3.country  AS country,
f.title AS film,
f.rating  AS rating,
l."name" AS "language",
f."length" AS "length", 
f.release_year AS release_year,
count(r.rental_id) AS film_popularity
FROM public.film f 
INNER JOIN public.inventory i ON i.film_id = f.film_id 
INNER JOIN public.rental r ON i.inventory_id = r.inventory_id 
INNER JOIN public.customer c2 ON r.customer_id = c2.customer_id 
INNER JOIN public.address a ON a.address_id = c2.address_id 
INNER JOIN public.city c ON a.city_id = c.city_id 
INNER JOIN public.country c3 ON c.country_id = c3.country_id
INNER JOIN public."language" l ON f.language_id = l.language_id
WHERE lower(c3.country) = ANY (SELECT lower(unnest(country_names)))							-- Filtering by the input country 
GROUP BY f.film_id, c3.country_id,l.language_id 
ORDER BY film_popularity DESC),
	most_popular_film as(
	SELECT
	pfc.country,
	max(pfc.film_popularity) AS film_popularity
	FROM popular_films_by_countries pfc
	GROUP BY pfc.country)
		SELECT pfc.country,
		pfc.film, pfc.rating,
		pfc."language",
		pfc."length", 
		pfc.release_year, 
		pfc.film_popularity 
		FROM popular_films_by_countries pfc
		INNER JOIN most_popular_film mpf ON mpf.film_popularity = pfc.film_popularity AND pfc.country = mpf.country;
		IF FOUND
		THEN 
		RETURN;
		ELSE
		RAISE NOTICE 'The most popular movie was not found for the selected country';			--Message if no rows match the input criteria
		END IF;
		END;
		$$
		LANGUAGE plpgsql;

--Checking the result of the function
SELECT * FROM public.most_popular_films_by_countries(array['Afghanistan','Brazil','United States']);

/*Task 4. Using the partial_title input parameter the function returns a list of movies available in stock.
 * The function starts with generating a sequence using a create sequence function in order to provide the row number for the final result set.
   In the next step it retrieves all the movies with partial title match, that are currently avaialble in stock and displays the 5 most recent rental related information, like the customer name and rental date.  */  
 
 
DROP FUNCTION IF EXISTS films_in_stock_by_title(IN partial_title text);
DROP SEQUENCE IF EXISTS row_number_seq;
CREATE SEQUENCE row_number_seq START 1;														--Creating a sequence for the row numbers in the result set
CREATE OR REPLACE FUNCTION films_in_stock_by_title(IN partial_title TEXT)
RETURNS table (
row_number bigint,
film_title TEXT,
"language" CHARACTER,
customer_name TEXT,
rental_date timestamp with time ZONE)
AS $$
BEGIN
RETURN QUERY
    WITH title_match_movie AS (																--Selecting the movies with partial title match
    SELECT 
    f.title,
    f.film_id,
    r.rental_date,
    l.name AS "language",
    concat(c.first_name, ' ', c.last_name) AS customer
    FROM public.film f 						
    INNER JOIN public.inventory i ON f.film_id = i.film_id
    INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
    INNER JOIN public.customer c ON r.customer_id = c.customer_id
    INNER JOIN public."language" l ON f.language_id = l.language_id
    WHERE lower(f.title) LIKE lower(partial_title) AND r.rental_date IN (
            SELECT r1.rental_date															--Selecting the rental dates for the 5 most recent rentals										
            FROM public.rental r1
            INNER JOIN public.inventory i1 ON r1.inventory_id = i1.inventory_id
            WHERE i1.film_id = f.film_id
            ORDER BY r1.rental_date DESC
            LIMIT 5)
        	ORDER BY f.film_id),
    			film_in_stock AS (
        		SELECT tmm.film_id,
				tmm.title,
				tmm.language,
				tmm.customer, 
				tmm.rental_date
        		FROM title_match_movie tmm
        		WHERE tmm.film_id NOT IN (
		            SELECT i.film_id
		            FROM public.inventory i   
		            INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
		            WHERE r.return_date IS NULL)) 									 -- Check if the film is currently rented out
				    	SELECT
						nextval('row_number_seq') AS row_number,					 -- Use nextval for automatic row number
				        fis.title AS film_title, 
				        fis.language,
				        fis.customer AS customer_name,
				        fis.rental_date
				    	FROM film_in_stock fis
				   		ORDER BY fis.film_id;  
						IF FOUND
						THEN 
						RETURN;
						ELSE
						RAISE NOTICE 'No movies found matching the title "%"', partial_title;
						END IF;
						END
						$$
						LANGUAGE plpgsql;
				
--Testing the function
SELECT * FROM public.films_in_stock_by_title('%love%');

/* Task 5. The function takes three input parameters, the first one is the movie title and two optional parameters for the movie language and relase year with the default values of Klingon and the current year respectively.
 * The main role of this function is to insert a new movie into the film table if the movie doesn't alrady exist and it returns the inserted movie's details.
 * If the specified language from the input doesn't exist in the database,a raise notice message displayed and the function inserts the language into the language table and retrieves the language_id which is necessary to populate the appropriate column in the film table.
 * If the language does exist in the language table then the function simply returns it.
 * If the language is not specified, then by default the movie gets inserted into the film table using the Klingon language.*/


DROP FUNCTION IF EXISTS new_movie(movie_title TEXT, movie_language TEXT, movie_release_year YEAR);
CREATE OR REPLACE FUNCTION new_movie(movie_title TEXT,movie_language TEXT DEFAULT 'Klingon',movie_release_year YEAR DEFAULT EXTRACT(YEAR FROM current_date)::YEAR)
RETURNS TABLE(film_id INT, title TEXT, language_id smallint, release_year YEAR, rental_duration SMALLINT, rental_rate NUMERIC, replacement_cost NUMERIC)
AS $$
DECLARE
selected_language_id smallint;																													--Storing the release year, either provided of default
BEGIN
IF NOT EXISTS (
        SELECT 1 FROM public."language" l WHERE lower(l.name) = lower(movie_language))
THEN
        RAISE NOTICE '% language does not exist. Inserting it.', movie_language;		--Message about missing language and inserting it
        INSERT INTO public."language"(name)
        VALUES (movie_language)
        RETURNING public.language.language_id INTO selected_language_id;
ELSE
        SELECT l.language_id INTO selected_language_id
        FROM public."language" l
        WHERE lower(l.name) = lower(movie_language);
END IF;
RETURN QUERY																			--Retreiving the rental related data and inserting the new movie in the film table
		WITH rental_data AS (
        SELECT f.rental_rate, f.rental_duration
        FROM public.film f
        WHERE f.film_id = 2),
	    	replacement_cost_data AS (
	        SELECT f.replacement_cost
	        FROM public.film f
	        WHERE f.film_id = 24)
		    	INSERT INTO public.film (title, language_id, release_year, rental_duration, rental_rate, replacement_cost)
		    	SELECT 
		        movie_title,
		        selected_language_id,
		        movie_release_year,
		        rd.rental_duration,
		        rd.rental_rate,
		        rcd.replacement_cost
		    	FROM rental_data rd
		    	CROSS JOIN replacement_cost_data rcd
		    	WHERE NOT EXISTS (
				        SELECT 1
				        FROM public.film f
				        WHERE LOWER(f.title) = LOWER(movie_title))
		    			RETURNING 
		        		film.film_id, film.title, film.language_id,film.release_year, film.rental_duration, film.rental_rate, film.replacement_cost;
						RAISE NOTICE 'Film is added to database';
						END;
						$$ LANGUAGE plpgsql;
--Testing the function
SELECT * FROM new_movie('Drive to survive','Hungarian',2015);

SELECT * FROM public.film f ORDER BY f.film_id DESC;
SELECT * FROM public."language" l ORDER BY l.language_id DESC;