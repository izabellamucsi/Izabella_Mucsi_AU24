/* 2.1 First Task: Created a table `table_to_delete`, containing 10,000,000 rows */

CREATE TABLE table_to_delete AS
               SELECT 'veeeeeeery_long_string' || x AS col
               FROM generate_series(1,(10^7)::int) x; -- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)
               
              

/* 2.2 Checking Table Size:
 * Used the query below to determine the size of `table_to_delete` after initial creation.
 * The table size was 575MB (602,480,640 bytes).
 */

SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';
               
              
/* 2.3 Deleting Rows:
 * Deleted 1/3 of the rows in `table_to_delete` where the row number is divisible by 3.
 * This deletion removes approximately 3,333,333 rows.
 */
EXPLAIN ANALYSE            
DELETE FROM table_to_delete
               WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all ROWS
               
SELECT count(*)                    -- 6.666.667 rows after the delete transaction
FROM public.table_to_delete
       
/*2.3.a The Execution Time: 9226.760 ms
 2.3.b Size Check Post-DELETE:
 * After deletion, I ran the previous query to check the table size. The table size remained 575MB (602,562,560 bytes),

 2.3.c VACUUM Operation:
 * Ran `VACUUM FULL` on `table_to_delete` to reclaim space occupied by deleted rows.*/
               
  VACUUM FULL VERBOSE table_to_delete;
 
 //* 2.3.d Post-VACUUM Size Check:
 * After running `VACUUM`, the table size reduced to 383 MB (401,580,032 bytes),
 * and the row count of to 6,666,667, matching the expected count after deleting 1/3 of the rows. 
 * In conclusion DELETE removed rows but did not reclaim the space, leaving the size unchanged until VACUUM was run.
 * VACUUM reclaimed space in the table, reducing the table size and adjusting the row count.*/

/* 2.3.e Table Recreation:
 * Dropped and recreated `table_to_delete` to restore it to the original 10,000,000 rows.
 */

DROP TABLE public.table_to_delete;
CREATE TABLE table_to_delete AS
               SELECT 'veeeeeeery_long_string' || x AS col
               FROM generate_series(1,(10^7)::int) x; -- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)
               
               

/* 2.4. Truncating the Table:
 * 2.4.a Ran `TRUNCATE` on `table_to_delete`, which instantly removed all rows.
 * The query took 2 seconds to execute as the start time of the operation was 14:45:47 and 
 * the finish time was 14:45:49. The execution of the delete transaction took much longer than the truncate.*/ 
 
  TRUNCATE public.table_to_delete; 
 
 */* 2.4.b Size Check Post-TRUNCATE:
 * Before truncation, `table_to_delete` was consuming 575 MB. After truncation, the size dropped to 0 bytes.
 * 2.4.c TRUNCATE is faster than DELETE and frees up space immediately without requiring a VACUUM operation.
