// Creates a table with the appropriate columns for dangerous_dogs.csv
CREATE TABLE dangerous_dogs(
first_name VARCHAR,
last_name VARCHAR,
address VARCHAR,
zip_code VARCHAR,
description_of_dog TEXT,
location VARCHAR,
latitude numeric,
longitude numeric
);

// Copies data from the VM file to the VM table
COPY dangerous_dogs FROM '/home/vagrant/code/mks/dangerous_dogs.csv' DELIMITER ',' CSV HEADER;

// view all entries for dangerous_dogs
SELECT * FROM dangerous_dogs;

// Using count expressions for dangerous_dogs
SELECT count(DISTINCT zip_code)
FROM dangerous_dogs;					#=> 22

SELECT count(zip_code), zip_code
FROM dangerous_dogs
GROUP BY zip_code
ORDER BY count desc;					#=> 78744

SELECT count(DISTINCT description_of_dog)
FROM dangerous_dogs
WHERE description_of_dog
LIKE '% male%';							#=> 15

SELECT count(DISTINCT description_of_dog)
FROM dangerous_dogs
WHERE description_of_dog
LIKE '%female%'; 						#=> 19

// "MONTH","AIRLINE_ID","CARRIER","ORIGIN_CITY_NAME","DEST_CITY_NAME","DEP_DELAY_NEW","ARR_DELAY_NEW"

// Creates a table with the appropriate columns for on_time_performance
CREATE TABLE on_time_performance(
MONTH INTEGER,
AIRLINE_ID INTEGER,
CARRIER VARCHAR(2),
ORIGIN_CITY_NAME VARCHAR,
DEST_CITY_NAME VARCHAR,
DEP_DELAY_NEW numeric,
ARR_DELAY_NEW numeric
);

// Copy data FROM .csv to table
COPY on_time_performance FROM '/home/vagrant/code/mks/on_time_performance.csv' DELIMITER ',' CSV HEADER;

1.
SELECT count(DISTINCT CARRIER)
FROM on_time_performance;				#=> 14

2.
SELECT count(DEP_DELAY_NEW) + count(ARR_DELAY_NEW), CARRIER
AS count
FROM on_time_performance
WHERE DEP_DELAY_NEW > 0
OR ARR_DELAY_NEW > 0
GROUP BY CARRIER
ORDER BY count DESC;					#=> WN ; VX

3.
SELECT count(DEP_DELAY_NEW), ORIGIN_CITY_NAME
FROM on_time_performance
WHERE DEP_DELAY_NEW > 0
GROUP BY ORIGIN_CITY_NAME
ORDER BY count desc;					#=> Chicago, IL

4.
SELECT count(ARR_DELAY_NEW), DEST_CITY_NAME
FROM on_time_performance
GROUP BY DEST_CITY_NAME
ORDER BY count desc;					#=>  Atlanta, GA

5.
SELECT ( SUM(ARR_DELAY_NEW) + SUM(DEP_DELAY_NEW) ) / (COUNT(ARR_DELAY_NEW) + COUNT(DEP_DELAY_NEW) ) AS average_minutes_late
FROM on_time_performance;				#=>  18.58
--OR--
SELECT ( (AVG(ARR_DELAY_NEW) + AVG(DEP_DELAY_NEW) ) / 2 ) AS average_minutes_late
FROM on_time_performance;				#=>  #=> 18.58

6.
SELECT CARRIER, ( SUM(ARR_DELAY_NEW) + SUM(DEP_DELAY_NEW) ) / ( COUNT(ARR_DELAY_NEW) + COUNT(DEP_DELAY_NEW) ) AS average_minutes_late
FROM on_time_performance
GROUP BY CARRIER
ORDER BY average_minutes_late desc;
--OR--
SELECT CARRIER, ( AVG(ARR_DELAY_NEW) + AVG(DEP_DELAY_NEW) ) / 2 AS average_minutes_late
FROM on_time_performance
GROUP BY CARRIER
ORDER BY average_minutes_late desc;


// Restaurant Name,Zip Code,Inspection Date,Score,Address,Facility ID,Process Description

CREATE TABLE restaurant_inspection_scores(
RestaurantName VARCHAR,
ZipCode VARCHAR,
InspectionDate VARCHAR,
Score INTEGER,
Address VARCHAR,
FacilityID NUMERIC,
ProcessDescription VARCHAR
);

// Copy data from .csv to table
COPY restaurant_inspection_scores FROM '/home/vagrant/code/mks/restaurant_inspection_scores.csv' DELIMITER ',' CSV HEADER;

1.
SELECT COUNT(DISTINCT ZipCode)
FROM restaurant_inspection_scores;		#=> 57

2.
SELECT ZipCode, COUNT(RestaurantName)
FROM restaurant_inspection_scores
GROUP BY ZipCode
ORDER BY count desc;

3.
SELECT ZipCode, SUM(Score) / COUNT(Score) AS Average
FROM restaurant_inspection_scores
GROUP BY ZipCode
ORDER BY Average desc;					#=>  78621
--OR--
SELECT ZipCode, AVG(Score) AS Average
FROM restaurant_inspection_scores
GROUP BY ZipCode
ORDER BY Average desc;  				#=> 78621

4.
SELECT MIN(Score)
FROM restaurant_inspection_scores;		#=> 45

5.
SELECT RestaurantName
FROM restaurant_inspection_scores
WHERE Score = 45;						#=>  Fran's Hamburgers
--OR--
SELECT RestaurantName, Score
FROM restaurant_inspection_scores
ORDER BY Score asc
LIMIT 5;

6.
SELECT FacilityID, RestaurantName, COUNT(Score)
FROM restaurant_inspection_scores
GROUP BY FacilityID, RestaurantName
ORDER BY count desc;					#=> 2800829 | Thai Kitchen | 8

