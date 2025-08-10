--Hung Duong
--Extra Credit

ALTER TABLE airquality_2002
ALTER COLUMN dates
TYPE date USING dates::DATE;
ALTER TABLE airquality_2012
ALTER COLUMN dates
TYPE date USING dates::DATE;
ALTER TABLE airquality_2022
ALTER COLUMN dates
TYPE date USING dates::DATE;

ALTER TABLE airquality_2022 
RENAME COLUMN "AQI" TO aqi;
ALTER TABLE airquality_2022 
RENAME COLUMN "Category" TO category;

--create a master table for easy access
DROP VIEW IF EXISTS master_view;
CREATE VIEW master_view AS 
	SELECT *
	FROM airquality_2002 
	UNION ALL 
	SELECT*
	FROM airquality_2012 
	UNION ALL 
	SELECT * 
	FROM airquality_2022;

--What is the average AQI (air quality index) by year by season (winter, spring, summer, fall)?
SELECT 
    EXTRACT(YEAR FROM mv.dates) AS years,
	CASE 
	WHEN extract(MONTH FROM mv.dates) IN (12,1,2) THEN 'Winter'
	WHEN extract(MONTH FROM mv.dates) IN (3,4,5) THEN 'Spring'
	WHEN extract(MONTH FROM mv.dates) IN (6,7,8) THEN 'Summer'
	WHEN extract(MONTH FROM mv.dates) IN (9,10,11) THEN 'Autumn'
	END AS seasons,
	round(avg(mv.aqi),2) AS average_aqi
FROM master_view AS mv
GROUP BY years,seasons
ORDER BY years; 

--What were the top 10 locations with worst AQI in each year?  
WITH rankedaqi AS (
    SELECT 
        county_name,
        state_name,
        defining_site,
        EXTRACT(YEAR FROM dates) AS years,
        ROUND(AVG(aqi), 2) AS average_aqi,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM dates) ORDER BY AVG(aqi) DESC) AS ranking
    FROM 
        master_view 
    GROUP BY 
        county_name,
        state_name,
        defining_site,
        years)
SELECT 
	years,
    county_name,
    state_name,
    defining_site,
    average_aqi, 
    ranking
FROM rankedaqi
WHERE ranking <= 10
ORDER BY years, ranking;

--What were the top 10 locations that had the best improvement over 20 years, from the first year to the most recent year? 
WITH aqi_2002 AS (
	SELECT 
	county_name,
    state_name,
    defining_site,
	EXTRACT(YEAR FROM dates) AS years,
	ROUND(AVG(aqi), 2) AS average_aqi
	FROM master_view 
	WHERE EXTRACT(YEAR FROM dates) = 2002
	GROUP BY county_name, state_name, defining_site, years) ,
aqi_2022 AS (
	SELECT 
	county_name,
    state_name,
    defining_site,
	EXTRACT(YEAR FROM dates) AS years,
	ROUND(AVG(aqi), 2) AS average_aqi
	FROM master_view 
	WHERE EXTRACT(YEAR FROM dates) = 2022
	GROUP BY county_name, state_name, defining_site, years ),
improvement_aqi_after_20years AS (
	SELECT 
	a2.county_name,
	a2.state_name,
    a2.defining_site,
    a2.average_aqi AS avg_aqi_2002,
    a22.average_aqi AS avg_aqi_2022,
    (a2.average_aqi-a22.average_aqi) AS improvement
	FROM aqi_2002 AS a2
	INNER JOIN aqi_2022 AS a22
	ON a2.defining_site = a22.defining_site)
SELECT 
	county_name,
	state_name,
    defining_site,
    avg_aqi_2002,
    avg_aqi_2022,
    improvement
FROM improvement_aqi_after_20years
ORDER BY improvement DESC
LIMIT 10;


--What were the 10 locations with the worst decline over 20 years?
WITH aqi_2002 AS (
	SELECT 
	county_name,
    state_name,
    defining_site,
	EXTRACT(YEAR FROM dates) AS years,
	ROUND(AVG(aqi), 2) AS average_aqi
	FROM master_view 
	WHERE EXTRACT(YEAR FROM dates) = 2002
	GROUP BY county_name, state_name, defining_site, years) ,
aqi_2022 AS (
	SELECT 
	county_name,
    state_name,
    defining_site,
	EXTRACT(YEAR FROM dates) AS years,
	ROUND(AVG(aqi), 2) AS average_aqi
	FROM master_view 
	WHERE EXTRACT(YEAR FROM dates) = 2022
	GROUP BY county_name, state_name, defining_site, years ),
decline_aqi_after_20years AS (
	SELECT 
	a2.county_name,
	a2.state_name,
    a2.defining_site,
    a2.average_aqi AS avg_aqi_2002,
    a22.average_aqi AS avg_aqi_2022,
    (a22.average_aqi-a2.average_aqi) AS declinement
	FROM aqi_2002 AS a2
	INNER JOIN aqi_2022 AS a22
	ON a2.defining_site = a22.defining_site)
SELECT 
	county_name,
	state_name,
    defining_site,
    avg_aqi_2002,
    avg_aqi_2022,
    declinement
FROM decline_aqi_after_20years
ORDER BY declinement DESC
LIMIT 10;

--In Utah counties, how many days of "Unhealthy" air did we have in each year?  Is it improving?
-- not totally understading the question, meaning for each counties? 
SELECT 
	EXTRACT(YEAR FROM dates) AS years,
	count(aqi) AS unhealthy_dates
FROM master_view 
WHERE category LIKE 'Unhealthy%'AND state_name LIKE 'Utah'
GROUP BY years;

--In Salt Lake County, which months have the most "Unhealthy" days?  Has that changed in 20 years?
WITH unhealthy_2002 AS(
SELECT 
    EXTRACT(YEAR FROM dates) AS years,
   	EXTRACT(MONTH FROM dates) AS months,
   	(COUNT( dates)) AS unhealthy_days,
   	RANK() OVER(ORDER BY COUNT( dates) DESC) AS order_rank
FROM airquality_2002 
WHERE 
	category LIKE 'Unhealthy%' 
	AND state_name = 'Utah'
	AND county_name = 'Salt Lake'
GROUP BY years, months
ORDER BY order_rank ASC
LIMIT 1
),
unhealthy_2022 AS (
SELECT 
    EXTRACT(YEAR FROM dates) AS years,
   	EXTRACT(MONTH FROM dates) AS months,
   	(COUNT( dates)) AS unhealthy_days,
   	RANK() OVER(ORDER BY COUNT( dates) DESC) AS order_rank
FROM airquality_2022 
WHERE 
	category LIKE 'Unhealthy%' 
	AND state_name = 'Utah'
	AND county_name = 'Salt Lake'
GROUP BY years, months
ORDER BY order_rank ASC
LIMIT 1
)
SELECT *
FROM unhealthy_2022
UNION ALL 
SELECT *
FROM unhealthy_2002;