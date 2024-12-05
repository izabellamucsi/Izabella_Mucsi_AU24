/*TASK:
 * 1.Create a physical database with a separate database and schema and give it an appropriate domain-related name. Use the relational model you've created while studying DB Basics module. 
 *3. Use appropriate data types for each column and apply DEFAULT values, and GENERATED ALWAYS AS columns as required.
  4.Create relationships between tables using primary and foreign keys.
  5.Apply five check constraints across the tables to restrict certain values */

/*The following statements are creating the physical database called political_campaign with a campaign schema and also implementing the  relationships between tables using primary and foreign keys. 
 * It includes the creation of several tables in line with the Political_campaign logical model, while applying various constraints, including not-null, check constraints (e.g., ensuring event dates are after January 1, 2000), and a generated column for Election_year. 
 * It also includes creating indexes for foreign keys for optimization.
 * The political_campaign busiess template was also updated with the summary of the modiications*/

DROP DATABASE IF EXISTS political_campaign;		
CREATE DATABASE political_campaign;		
COMMIT;	

-- Connecting to the political_campaign database before creating the schema
CREATE SCHEMA IF NOT EXISTS campaign;
COMMIT;	
--Creating the tables in line with the data model
BEGIN;
DROP TABLE IF EXISTS campaign.Country CASCADE;		
CREATE TABLE IF NOT EXISTS campaign.Country (		
	Country_id serial  PRIMARY KEY,	
	Country_name varchar(20) NOT NULL);			
		
DROP TABLE IF EXISTS campaign.City_demographics CASCADE;		
CREATE TABLE IF NOT EXISTS campaign.City_demographics (		
	City_id serial  PRIMARY KEY,	
	City_name varchar(20) NOT NULL,	
	Country_id integer,	
	Population integer,	
	Registered_voters integer,	
	Zip_code integer,
	CONSTRAINT FK_City_demographics_Country FOREIGN KEY (Country_id) REFERENCES campaign.Country (Country_id) ON DELETE RESTRICT ON UPDATE CASCADE);	
CREATE INDEX IXFK_City_demographics_Country ON campaign.City_demographics (Country_id ASC);		
	
		
DROP TABLE IF EXISTS campaign.Location CASCADE;		
CREATE TABLE IF NOT EXISTS campaign.Location (		
	Location_id serial PRIMARY KEY,	
	Location_name varchar(50),	
	Location_address varchar(50));		
		
		
DROP TABLE IF EXISTS campaign.Events CASCADE;		
CREATE TABLE  IF NOT EXISTS campaign.Events (		
	Event_id serial PRIMARY KEY,	
	Event_name varchar(20) NOT NULL,	
	Location_id integer,	
	Event_date date NOT NULL CHECK (Event_date >= '2000-01-01'),	
	City_id integer,	
	Election_year integer NOT NULL GENERATED ALWAYS AS (EXTRACT(YEAR FROM Event_date)) STORED,	
	CONSTRAINT FK_Events_City_demographics FOREIGN KEY (City_id) REFERENCES campaign.City_demographics (City_id) ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT FK_Events_Location FOREIGN KEY (Location_id) REFERENCES campaign.Location (Location_id) ON DELETE RESTRICT ON UPDATE CASCADE);	
CREATE INDEX IXFK_Events_City_demographics ON campaign.Events (City_id ASC);		
CREATE INDEX IXFK_Events_Location ON campaign.Events (Location_id ASC);		
	
		
DROP TABLE IF EXISTS campaign.Candidates CASCADE;		
CREATE TABLE  IF NOT EXISTS campaign.Candidates (		
	Candidate_id serial PRIMARY KEY,	
	Candidate_name varchar(20) NOT NULL,	
	Political_party_name varchar(50) NOT NULL);
CREATE INDEX IXFK_Candidates_m2m_Event_participation ON campaign.Candidates (Candidate_id ASC);		
	
		
DROP TABLE IF EXISTS campaign.Voters CASCADE;		
CREATE TABLE  IF NOT EXISTS campaign.Voters (		
	Voter_id char(13) PRIMARY KEY,	
	Email_address varchar(50) NOT NULL UNIQUE CHECK (Email_address LIKE '%@%.%'),	
	Voter_name varchar(50) NOT NULL,	
	Age smallint,	
	Gender char(1) CHECK (Gender IN ('M', 'F','O')),	
	Occupation text,	
	City_id integer,	
	CONSTRAINT FK_Voters_City_demographics FOREIGN KEY (City_id) REFERENCES campaign.City_demographics (City_id) ON DELETE RESTRICT ON UPDATE CASCADE);	

		
DROP TABLE IF EXISTS campaign.Campaign_donors CASCADE;		
CREATE TABLE IF NOT EXISTS  campaign.Campaign_donors (		
	Donor_id char(13) PRIMARY KEY,	
	Donor_name varchar(20) NOT NULL,	
	Phone VARCHAR(20),	
	Email_address varchar(50) NOT NULL UNIQUE CHECK (Email_address LIKE '%@%.%'),	
	Purpose text,	
	Account_number char(9));	
	
				
DROP TABLE IF EXISTS campaign.Campaign_volunteers CASCADE;		
CREATE TABLE  IF NOT EXISTS campaign.Campaign_volunteers (		
	Volunteer_id char(13)  PRIMARY KEY,	
	Volunteer_name varchar(50) NOT NULL,	
	Phone VARCHAR(20),	
	Email_address varchar(50) NOT NULL UNIQUE CHECK (Email_address LIKE '%@%.%'),	
	Volunteer_start_date date NOT NULL CHECK (Volunteer_start_date >= '2000-01-01'),	
	City_id integer,	
	CONSTRAINT FK_Campaign_volunteers_City_demographics FOREIGN KEY (City_id) REFERENCES campaign.City_demographics (City_id) ON DELETE RESTRICT ON UPDATE CASCADE);	
CREATE INDEX IXFK_Campaign_volunteers_City_demographics ON campaign.Campaign_volunteers (City_id ASC);		

		
DROP TABLE IF EXISTS campaign.Campaign_tasks CASCADE;		
CREATE TABLE IF NOT EXISTS campaign.Campaign_tasks (		
	Task_id serial  PRIMARY KEY,	
	Task_description text NOT NULL,	
	Priority smallint CHECK (Priority IN (1, 2, 3, 4, 5)));		
		
		
DROP TABLE IF EXISTS campaign.Contribution CASCADE;		
CREATE TABLE  IF NOT EXISTS campaign.Contribution (		
	Contribution_id serial PRIMARY KEY,	
	Contribution_type varchar(20),	
	Campaign_volunteer_id char(13),	
	Campaign_donor_id char(13),	
	Contribution_date date CHECK (Contribution_date >= '2000-01-01'),	
	Election_year integer NOT NULL GENERATED ALWAYS AS (EXTRACT(YEAR FROM Contribution_date)) STORED,
	CONSTRAINT UQ_Unique_Contribution UNIQUE (Contribution_id,Contribution_type,Contribution_date),
	CONSTRAINT FK_Contribution_Campaign_donors FOREIGN KEY (Campaign_donor_id) REFERENCES campaign.Campaign_donors (Donor_id) ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT FK_Contribution_Campaign_volunteers FOREIGN KEY (Campaign_volunteer_id) REFERENCES campaign.Campaign_volunteers (Volunteer_id) ON DELETE RESTRICT ON UPDATE CASCADE);	
CREATE INDEX IXFK_Contribution_Campaign_donors ON campaign.Contribution (Campaign_donor_id ASC);		
CREATE INDEX IXFK_Contribution_Campaign_volunteers ON campaign.Contribution (Campaign_volunteer_id ASC);		
	
		
DROP TABLE IF EXISTS campaign.Finances CASCADE;		
CREATE TABLE  IF NOT EXISTS campaign.Finances (		
	Transaction_reference Varchar(10) PRIMARY KEY,	
	Transaction_type varchar(20) NOT NULL,	
	Incoming_payment NUMERIC CHECK (Incoming_payment >= 0),	
	Outgoing_payment NUMERIC CHECK (Outgoing_payment >= 0),	
	Transaction_date date NOT NULL CHECK (Transaction_date >= '2000-01-01'),	
	Currency char(3) DEFAULT 'USD',	
	Account_number CHAR(9) NOT NULL,	
	Donor_id char(13),	
	Event_id integer,	
	CONSTRAINT FK_Finances_Campaign_donors FOREIGN KEY (Donor_id) REFERENCES campaign.Campaign_donors (Donor_id) ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT FK_Finances_Events FOREIGN KEY (Event_id) REFERENCES campaign.Events (Event_id) ON DELETE RESTRICT ON UPDATE CASCADE);	
CREATE INDEX IXFK_Finances_Campaign_donors ON campaign.Finances (Donor_id ASC);		
CREATE INDEX IXFK_Finances_Events ON campaign.Finances (Event_id ASC);		
		
		
DROP TABLE IF EXISTS campaign.Surveys CASCADE;		
CREATE TABLE  IF NOT EXISTS campaign.Surveys (		
	Survey_id serial PRIMARY KEY,	
	Survey_type varchar(20) NULL CHECK (Survey_type IN ('online', 'face to face', 'via phone', 'paper survey')),	
	Survey_date date CHECK (Survey_date >= '2000-01-01'),	
	Candidate_id integer NOT NULL,	
	CONSTRAINT UQ_Unique_Surveys UNIQUE (Survey_type, Survey_date, Candidate_id),
	CONSTRAINT FK_Surveys_Candidates FOREIGN KEY (Candidate_id) REFERENCES campaign.Candidates (Candidate_id) ON DELETE RESTRICT ON UPDATE CASCADE);	
CREATE INDEX IXFK_Surveys_Candidates ON campaign.Surveys (Candidate_id ASC);		

		
DROP TABLE IF EXISTS campaign.Survey_result CASCADE;		
CREATE TABLE  IF NOT EXISTS campaign.Survey_result (		
	Survey_result_id serial PRIMARY KEY,	
	Answer_date date NOT NULL CHECK (Answer_date >= '2000-01-01'),	
	Voter_id char(13),	
	Candidate_id integer,	
	CONSTRAINT FK_Survey_result_Candidates FOREIGN KEY (Candidate_id) REFERENCES campaign.Candidates (Candidate_id) ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT FK_Survey_result_Voters FOREIGN KEY (Voter_id) REFERENCES campaign.Voters (Voter_id) ON DELETE RESTRICT ON UPDATE CASCADE);	
CREATE INDEX IXFK_Survey_result_Candidates ON campaign.Survey_result (Candidate_id ASC);		
CREATE INDEX IXFK_Survey_result_Voters ON campaign.Survey_result (Voter_id ASC);		
	
		
DROP TABLE IF EXISTS campaign.m2m_Contribution_event CASCADE;		
CREATE TABLE  IF NOT EXISTS campaign.m2m_Contribution_event (		
	Contribution_id integer,	
	Event_id integer,	
	Value NUMERIC CHECK (Value >= 0),	
	PRIMARY KEY (Contribution_id, Event_id),	
	CONSTRAINT FK_m2m_Contribution_event_Contribution FOREIGN KEY (Contribution_id) REFERENCES campaign.Contribution (Contribution_id) ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT FK_m2m_Contribution_event_Events FOREIGN KEY (Event_id) REFERENCES campaign.Events (Event_id) ON DELETE RESTRICT ON UPDATE CASCADE);	
CREATE INDEX IXFK_m2m_Contribution_event_Contribution ON campaign.m2m_Contribution_event (Contribution_id ASC);		
CREATE INDEX IXFK_m2m_Contribution_event_Events ON campaign.m2m_Contribution_event (Event_id ASC);			
		
		
DROP TABLE IF EXISTS campaign.m2m_Event_participation CASCADE;		
CREATE TABLE  IF NOT EXISTS campaign.m2m_Event_participation (		
	Event_id integer,	
	Candidate_id integer,	
	Role varchar(20),	
	Participation_date date CHECK (Participation_date >= '2000-01-01'),	
	PRIMARY KEY (Event_id, Candidate_id),	
	CONSTRAINT FK_m2m_Event_participation_Events FOREIGN KEY (Event_id) REFERENCES campaign.Events (Event_id) ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT FK_m2m_Event_participation_Candidates FOREIGN KEY (Candidate_id) REFERENCES campaign.Candidates (Candidate_id) ON DELETE RESTRICT ON UPDATE CASCADE);	
CREATE INDEX IXFK_m2m_Event_participation_Events ON campaign.m2m_Event_participation (Event_id ASC);			
		
DROP TABLE IF EXISTS campaign.m2m_Volunteers_tasks CASCADE;		
CREATE TABLE IF NOT EXISTS  campaign.m2m_Volunteers_tasks (		
	Volunteer_id char(13),	
	Task_id integer,	
	Status varchar(20) NOT NULL CHECK (Status IN ('Not yet started', 'In progress', 'Finished')),	
	PRIMARY KEY (Volunteer_id, Task_id),	
	CONSTRAINT FK_m2m_Volunteers_tasks_Campaign_tasks FOREIGN KEY (Task_id) REFERENCES campaign.Campaign_tasks (Task_id) ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT FK_m2m_Volunteers_tasks_Campaign_volunteers FOREIGN KEY (Volunteer_id) REFERENCES campaign.Campaign_volunteers (Volunteer_id) ON DELETE RESTRICT ON UPDATE CASCADE);	
CREATE INDEX IXFK_m2m_Volunteers_tasks_Campaign_tasks ON campaign.m2m_Volunteers_tasks (Task_id ASC);		
CREATE INDEX IXFK_m2m_Volunteers_tasks_Campaign_volunteers ON campaign.m2m_Volunteers_tasks (Volunteer_id ASC);		

COMMIT;		

/*TASK:
 * 6.Populate the tables with the sample data generated, ensuring each table has at least two rows (for a total of 20+ rows in all the tables).
  7.Add a not null 'record_ts' field to each table using ALTER TABLE statements, set the default value to current_date, and check to make sure the value has been set for the existing rows.*/

/* The following statements are populating the defined tables bas on the Political_campaign logical model with sample data, where each table contains at least two rows. 
 * It also adds a record_ts column to each table using an ALTER TABLE statement. 
 * Additionally, it includes an UPDATE statement to populate the record_ts column for existing records where it is missing.*/
 

BEGIN;
--Inserting rows into campaign.Country,campaign.City_demographics and campaign.Location tables and adding a new column record_ts to store the timestamp

WITH country_data AS (
SELECT 'USA' AS country_name
UNION ALL
SELECT 'CANADA' AS country_name),
	demographics_data AS (
	SELECT
	'Alabama' AS city_name,
	27000 AS population,
	20000 AS registered_voters,
	36526 AS zip_code,
	'USA' AS country_name
	UNION ALL
	SELECT
	'Madison' AS city_name,
	273372 AS population,
	176000 AS registered_voters,
	53701 AS zip_code,
	'USA' AS country_name),
		location_data AS (
		SELECT
		'Town Hall' AS location_name,
		'8 Campus Drive' AS location_address
		UNION ALL
		SELECT
		'Alabama State Capitol' AS location_name,
		'600 Dexter Ave' AS location_address),
			inserted_countries AS (
			INSERT INTO campaign.country (country_name)
			SELECT cd.country_name
			FROM country_data cd
			WHERE NOT EXISTS (
			SELECT * FROM campaign.country cc WHERE cc.country_name = cd.country_name)
			RETURNING country_id, country_name),
				inserted_city_demographics AS (
				INSERT INTO campaign.city_demographics (city_name, country_id, population, registered_voters, zip_code)
				SELECT dd.city_name, ic.country_id, dd.population, dd.registered_voters, dd.zip_code
				FROM demographics_data dd
				JOIN inserted_countries ic ON ic.country_name = dd.country_name
				WHERE NOT EXISTS (
				SELECT * FROM campaign.city_demographics ccd WHERE ccd.city_name = dd.city_name)
				RETURNING city_id, city_name)
					INSERT INTO campaign.location (location_name, location_address)
					SELECT ld.location_name, ld.location_address
					FROM location_data ld
					WHERE NOT EXISTS (
					SELECT * FROM campaign.location cl WHERE cl.location_name = ld.location_name)
					RETURNING location_id, location_name;
					SELECT * FROM campaign.country;
					SELECT * FROM campaign.city_demographics;
					SELECT * FROM campaign.location;
				
ALTER TABLE campaign.City_demographics ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
UPDATE campaign.City_demographics SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE campaign.Country ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
UPDATE campaign.Country SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE campaign.Location ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;				
UPDATE campaign.Location SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;

--Inserting rows into campaign.Events  table and adding a new column record_ts to store the timestamp

WITH Events_data AS (
SELECT
'Town Hall Meeting' AS event_name,
(SELECT cl.location_id
FROM campaign.location cl
WHERE lower(cl.location_name) LIKE '%town hall%'
LIMIT 1) AS location_id,
CAST('2024-01-01' AS date) AS event_date,
(SELECT cd.city_id
FROM campaign.city_demographics cd
WHERE lower(cd.city_name) = 'madison') AS city_id
UNION ALL
SELECT
'Political Forum' AS event_name,
(SELECT cl.location_id
FROM campaign.location cl
WHERE lower(cl.location_name) LIKE '%capitol%'
LIMIT 1) AS location_id,
CAST('2024-03-01' AS date)AS event_date,
(SELECT cd.city_id
FROM campaign.city_demographics cd
WHERE lower(cd.city_name) = 'alabama') AS city_id)
INSERT INTO campaign.events (event_name, location_id, event_date, city_id)
	SELECT ed.event_name, ed.location_id, ed.event_date, ed.city_id
	FROM Events_data ed
	WHERE NOT EXISTS (
				    SELECT *
				    FROM campaign.Events ce
				    WHERE  ce.event_name = ed.event_name);
ALTER TABLE campaign.Events ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
UPDATE campaign.Events SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;

--Inserting rows into campaign.Candidates  table and adding a new column record_ts to store the timestamp

WITH candidates_data AS (
SELECT
'Emily Brown' AS candidate_name,
'Independent Party' AS political_party_name
UNION ALL
SELECT
'Alex Carter' AS candidate_name,
'The Progress Alliance' AS political_party_name)
INSERT INTO campaign.candidates (candidate_name, political_party_name)
	SELECT cd.candidate_name, cd.political_party_name
	FROM candidates_data cd
	WHERE NOT EXISTS (
				    SELECT *
				    FROM campaign.candidates cc
				    WHERE cc.candidate_name = cd.candidate_name);
				   
ALTER TABLE campaign.Candidates ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;				
UPDATE campaign.Candidates SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;			   

--Inserting rows into campaign.Voters  table and adding a new column record_ts to store the timestamp

WITH voter_data AS (
    SELECT
        '0510992823100' AS voter_id,
        'James_Smith@gmail.com' AS email_address,
        'James Smith' AS voter_name,
        40 AS age,
        'M' AS gender,
        'Professor' AS occupation,
        (SELECT cd.city_id
FROM campaign.city_demographics cd
WHERE lower(cd.city_name) = 'madison') AS city_id
    UNION ALL
    SELECT
        '0510992823200' voter_id, 
        'Jane_Smith@gmail.com'AS email_address,
        'Jane Smith' AS voter_name,
        38 AS age,
        'F'AS gender,
        'Developer'AS occupation,
        (SELECT cd.city_id
FROM campaign.city_demographics cd
WHERE lower(cd.city_name) = 'madison') AS city_id)
INSERT INTO campaign.voters (voter_id, email_address, voter_name, age, gender, occupation,city_id)
SELECT v.voter_id, v.email_address, v.voter_name, v.age, v.gender, v.occupation,v.city_id
FROM voter_data v
WHERE NOT EXISTS (
    SELECT *
    FROM campaign.voters cv
    WHERE cv.voter_id = v.voter_id)
ON CONFLICT (email_address) DO NOTHING;

ALTER TABLE campaign.Voters ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
UPDATE campaign.Voters SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;

--Inserting rows into campaign.Campaign_donors  table and adding a new column record_ts to store the timestamp

WITH donors_data AS (
SELECT
'0811999825200'AS donor_id,
'Sophie Evans' AS donor_name,
'812613' AS phone,
'Evansllc@gmail.com' AS email_address,
'Sponsorship' AS purpose,
'511234567' AS account_number
UNION ALL
SELECT
'0510999825200' AS donor_id,
'Sarah Johnson' AS donor_name,
'812513' AS phone,
'sarah.johnson@yahoo.com' AS email_address,
'Education Fund' AS purpose,
'987654321' AS account_number)
INSERT INTO campaign.campaign_donors (donor_id, donor_name, phone, email_address, purpose, account_number)
	SELECT dd.donor_id, dd.donor_name, dd.phone, dd.email_address, dd.purpose, dd.account_number
	FROM donors_data dd
	WHERE NOT EXISTS (
				    SELECT *
				    FROM campaign.campaign_donors cd
				    WHERE cd.donor_id = dd.donor_id)
				    ON CONFLICT (email_address) DO NOTHING;
				    
ALTER TABLE campaign.Campaign_donors ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;				   
UPDATE campaign.Campaign_donors SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;

--Inserting rows into campaign.Campaign_volunteers  table and adding a new column record_ts to store the timestamp

WITH volunteer_data AS (
SELECT
'0210996826300' AS volunteer_id,
'John Williams' AS volunteer_name,
'812546' AS phone,
'JW@gmail.com' AS email_address,
CAST('2021-01-01' AS date) AS volunteer_start_date,
(SELECT cd.city_id
FROM campaign.city_demographics cd
WHERE lower(cd.city_name) = 'madison') AS city_id
UNION ALL
SELECT
'0210982526300' AS volunteer_id,
'Alex Carter' AS volunteer_name,
'812566' AS phone,
'alex.carter@gmail.com' AS email_address,
CAST('2022-01-01' AS date) AS volunteer_start_date,
(SELECT cd.city_id
FROM campaign.city_demographics cd
WHERE lower(cd.city_name) = 'alabama')AS city_id)
INSERT INTO campaign.campaign_volunteers (volunteer_id, volunteer_name, phone, email_address, volunteer_start_date, city_id)
	SELECT vd.volunteer_id, vd.volunteer_name, vd.phone, vd.email_address, vd.volunteer_start_date, vd.city_id
	FROM volunteer_data vd
	WHERE NOT EXISTS (
				    SELECT *
				    FROM campaign.campaign_volunteers cv
				    WHERE cv.volunteer_id = vd.volunteer_id)
				    ON CONFLICT (email_address) DO NOTHING;
				   
ALTER TABLE campaign.Campaign_volunteers ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;				   
UPDATE campaign.Campaign_volunteers SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;

--Inserting rows into campaign.Campaign_tasks  table and adding a new column record_ts to store the timestamp

WITH tasks_data AS (
SELECT
'Data collection' AS task_description,
2 AS priority
UNION ALL
SELECT
'Interview' AS task_description,
3 AS priority)
INSERT INTO campaign.campaign_tasks (task_description, priority)
	SELECT td.task_description, td.priority
	FROM tasks_data td
	WHERE NOT EXISTS (
				    SELECT *
				    FROM campaign.campaign_tasks ct
				    WHERE  ct.task_description = td.task_description);
				   
ALTER TABLE campaign.Campaign_tasks ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;				   
UPDATE campaign.Campaign_tasks SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;  

--Inserting rows into campaign.Contribution  table and adding a new column record_ts to store the timestamp

WITH contribution_data AS (
SELECT
'Food' AS contribution_type,
(SELECT cv.volunteer_id
FROM campaign.campaign_volunteers cv 
WHERE lower(cv.volunteer_name) = 'john williams') AS campaign_volunteer_id,
NULL AS campaign_donor_id,
CAST('2024-01-01' AS date) AS contribution_date
UNION ALL
SELECT
'Decoration' AS contribution_type,
(SELECT cv.volunteer_id
FROM campaign.campaign_volunteers cv 
WHERE lower(cv.volunteer_name) = 'alex carter') AS campaign_volunteer_id,
NULL AS campaign_donor_id,
CAST('2024-03-01' AS date) AS contribution_date)
INSERT INTO campaign.contribution (contribution_type, campaign_volunteer_id, campaign_donor_id, contribution_date)
	SELECT cd.contribution_type, cd.campaign_volunteer_id, cd.campaign_donor_id, cd.contribution_date
	FROM contribution_data cd
	ON CONFLICT ON CONSTRAINT UQ_Unique_Contribution DO NOTHING;
	
ALTER TABLE campaign.Contribution ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
UPDATE campaign.Contribution SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;

--Inserting rows into campaign.Finances  table and adding a new column record_ts to store the timestamp

WITH finances_data AS (
SELECT
'0123'AS transaction_reference,
'wire transfer' AS transaction_type,
1000 AS incoming_payment,
0 AS outgoing_payment,
CAST('2024-01-01' AS date)AS transaction_date,
(SELECT cd.donor_id  
FROM campaign.campaign_donors cd
WHERE cd.account_number = '511234567') AS donor_id,
(SELECT cd.account_number 
FROM campaign.campaign_donors cd
WHERE cd.donor_id = '0811999825200')AS account_number,
(SELECT ce.event_id
FROM campaign.events ce
WHERE lower(ce.event_name) LIKE '%town hall%'
LIMIT 1)AS event_id
UNION ALL
SELECT
'0224'AS transaction_reference,
'cash' AS transaction_type,
50000 AS incoming_payment,
0 AS outgoing_payment,
CAST('2024-01-02' AS date) AS transaction_date,
(SELECT cd.donor_id  
FROM campaign.campaign_donors cd
WHERE cd.account_number = '987654321') AS donor_id,
(SELECT cd.account_number 
FROM campaign.campaign_donors cd
WHERE cd.donor_id = '0510999825200')AS account_number,
(SELECT ce.event_id
FROM campaign.events ce
WHERE lower(ce.event_name) LIKE '%forum%'
LIMIT 1)AS event_id)
INSERT INTO campaign.finances (transaction_reference, transaction_type, incoming_payment, outgoing_payment, transaction_date, account_number, donor_id, event_id)
	SELECT fd.transaction_reference, fd.transaction_type, fd.incoming_payment, fd.outgoing_payment, fd.transaction_date, fd.account_number, fd.donor_id, fd.event_id
	FROM finances_data fd
	WHERE NOT EXISTS (
				    SELECT *
				    FROM campaign.finances cf
				    WHERE cf.transaction_reference = fd.transaction_reference);

ALTER TABLE campaign.Finances ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;				   
UPDATE campaign.Finances SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;

--Inserting rows into campaign.Surveys  table and adding a new column record_ts to store the timestamp

WITH surveys_data AS (
SELECT
'online'AS survey_type,
CAST('2024-01-02' AS date) AS survey_date,
(SELECT cc.candidate_id
FROM campaign.candidates cc
WHERE cc.candidate_name = 'Emily Brown'
limit 1) AS candidate_id
UNION ALL
SELECT
'paper survey' AS survey_type,
CAST('2024-01-02' AS date)AS survey_date,
(SELECT cc.candidate_id
FROM campaign.candidates cc
WHERE cc.candidate_name = 'Alex Carter'
limit 1) AS candidate_id)
INSERT INTO campaign.surveys (survey_type, survey_date, candidate_id)
	SELECT sd.survey_type, sd.survey_date, sd.candidate_id
	FROM surveys_data sd
	ON CONFLICT ON CONSTRAINT UQ_Unique_Surveys DO NOTHING;

ALTER TABLE campaign.Surveys ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;				    
UPDATE campaign.Surveys SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;

--Inserting rows into campaign.Survey_result  table and adding a new column record_ts to store the timestamp

WITH survey_result_data AS (
SELECT
CAST('2024-01-01' AS date) AS answer_date,
(SELECT v.voter_id
FROM campaign.voters v 
WHERE lower(v.voter_name) = 'james smith') AS voter_id,
(SELECT cc.candidate_id
FROM campaign.candidates cc
WHERE cc.candidate_name = 'Emily Brown'
limit 1) AS candidate_id
UNION ALL
SELECT
CAST('2024-03-01' AS date) AS answer_date,
(SELECT v.voter_id
FROM campaign.voters v 
WHERE lower(v.voter_name) = 'jane smith')AS voter_id,
(SELECT cc.candidate_id
FROM campaign.candidates cc
WHERE cc.candidate_name = 'Alex Carter'
limit 1) AS candidate_id)
INSERT INTO campaign.survey_result (answer_date, voter_id, candidate_id)
	SELECT srd.answer_date, srd.voter_id, srd.candidate_id
	FROM survey_result_data srd;

ALTER TABLE campaign.Survey_result ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;	
UPDATE campaign.Survey_result SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;

--Inserting rows into campaign.m2m_Contribution_event  table and adding a new column record_ts to store the timestamp

WITH contribution_event_data AS (
SELECT
(SELECT c.contribution_id
FROM campaign.contribution c 
WHERE c.campaign_volunteer_id = '0210996826300' AND c.contribution_date = '2024-01-01') AS contribution_id,
(SELECT e.event_id
FROM campaign.events e
WHERE lower(e.event_name) LIKE '%town hall%' AND e.event_date = '2024-01-01') AS event_id,
200 AS value
UNION ALL
SELECT
(SELECT c.contribution_id
FROM campaign.contribution c 
WHERE c.campaign_volunteer_id = '0210982526300' AND c.contribution_date = '2024-03-01')AS contribution_id,
(SELECT e.event_id
FROM campaign.events e
WHERE lower(e.event_name) LIKE '%political forum%' AND e.event_date = '2024-03-01') AS event_id,
500 AS value)
INSERT INTO campaign.m2m_contribution_event (contribution_id, event_id, value)
	SELECT ced.contribution_id, ced.event_id, ced.value
	FROM contribution_event_data ced;

ALTER TABLE campaign.m2m_Contribution_event ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;	
UPDATE campaign.m2m_Contribution_event SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;

--Inserting rows into campaign.m2m_Event_participation  table and adding a new column record_ts to store the timestamp

WITH event_participation_data AS (
SELECT
(SELECT e.event_id
FROM campaign.events e
WHERE lower(e.event_name) LIKE '%town hall%' AND e.event_date = '2024-01-01')AS event_id,
(SELECT c.candidate_id
FROM campaign.candidates c 
WHERE lower(c.candidate_name) = 'emily brown') AS candidate_id,
'Speaker' AS "role",
(SELECT e.event_date
FROM campaign.events e
WHERE lower(e.event_name) LIKE '%town hall%')AS participation_date
UNION ALL
SELECT
(SELECT e.event_id
FROM campaign.events e
WHERE lower(e.event_name) LIKE '%political forum%' AND e.event_date = '2024-03-01') AS event_id,
(SELECT c.candidate_id
FROM campaign.candidates c 
WHERE lower(c.candidate_name) = 'alex carter')AS candidate_id,
'Presenter' AS "role",
(SELECT e.event_date
FROM campaign.events e
WHERE lower(e.event_name) LIKE '%political forum%')AS participation_date)
INSERT INTO campaign.m2m_event_participation (event_id, candidate_id, "role", participation_date)
	SELECT epd.event_id, epd.candidate_id, epd."role", epd.participation_date
	FROM event_participation_data epd;

ALTER TABLE campaign.m2m_Event_participation ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
UPDATE campaign.m2m_Event_participation SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;

--Inserting rows into campaign.m2m_Volunteers_tasks  table and adding a new column record_ts to store the timestamp

WITH volunteers_tasks_data AS (
SELECT
(SELECT cv.volunteer_id
FROM campaign.campaign_volunteers cv
WHERE lower(cv.volunteer_name) = 'john williams') AS volunteer_id,
(SELECT ct.task_id
FROM campaign.campaign_tasks ct 
WHERE lower(ct.task_description) = 'data collection') AS task_id,
'Finished' AS status
UNION ALL
SELECT
(SELECT cv.volunteer_id
FROM campaign.campaign_volunteers cv
WHERE lower(cv.volunteer_name) = 'alex carter')AS volunteer_id,
(SELECT ct.task_id
FROM campaign.campaign_tasks ct 
WHERE lower(ct.task_description) = 'interview')AS task_id,
'Finished' AS status)
INSERT INTO campaign.m2m_volunteers_tasks (volunteer_id, task_id, status)
	SELECT vtd.volunteer_id, vtd.task_id, vtd.status
	FROM volunteers_tasks_data vtd;
ALTER TABLE campaign.m2m_Volunteers_tasks ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;	
UPDATE campaign.m2m_Volunteers_tasks SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;

COMMIT;

--Checking the content of the inserted rows:

SELECT * FROM  campaign.Country;
SELECT * FROM  campaign.City_demographics;
SELECT * FROM  campaign.Location;
SELECT * FROM  campaign.Events;
SELECT * FROM  campaign.Candidates;
SELECT * FROM  campaign.Voters;
SELECT * FROM  campaign.Campaign_donors;
SELECT * FROM  campaign.Campaign_volunteers;
SELECT * FROM  campaign.Campaign_tasks;
SELECT * FROM  campaign.Contribution;
SELECT * FROM  campaign.Finances;
SELECT * FROM  campaign.Surveys;
SELECT * FROM  campaign.Survey_result;
SELECT * FROM  campaign.m2m_Contribution_event;
SELECT * FROM  campaign.m2m_Event_participation;
SELECT * FROM  campaign.m2m_Volunteers_tasks;
