# AFTER IMPORTING DATA

use Project3;

# DATA PREPARATION

CREATE VIEW jobs_data AS (
SELECT 
	STR_TO_DATE(ds, '%m/%d/%Y') AS ds,
    job_id,
    actor_id,
    event,
    language,
    time_spent,
    org
FROM 
	job_data
);

CREATE VIEW events_data AS (
SELECT 
	user_id, 
	STR_TO_DATE(occurred_at, '%d-%m-%Y %H:%i') AS occurred_at,
    event_type, 
    event_name,
    location,
    device,
    user_type
FROM 
	events
);

CREATE VIEW mail_events AS (
SELECT 
	user_id, 
	STR_TO_DATE(occurred_at, '%d-%m-%Y %H:%i') AS occurred_at,
    action,
    user_type
FROM 
	email_events
);


# CALCULATE THE NUMBER OF JOBS REVIEWED PER HOUR FOR EACH DAY

SELECT 
    ds AS date_reviewed,
    COUNT(*)/24 AS jobs_per_hour
FROM
    jobs_data
GROUP BY ds
ORDER BY ds;


# CALCULATE THE 7-DAY ROLLING AVERAGE OF THROUGHPUT

SELECT
	AVG(count(*)) 
		OVER (ORDER BY ds ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) 
        AS rolling_avg,
	ds AS date_reviewed
FROM jobs_data
GROUP BY ds;


# CALCULATE THE PERCENTAGE SHARE OF EACH LANGUAGE IN THE LAST 30 DAYS

SELECT 
    language,
    ( COUNT(*)*100 ) / ( SUM(COUNT(*)) OVER()) AS lang_percent
FROM jobs_data
GROUP BY language;
    

# IDENTIFY DUPLICATE ROWS IN THE DATA

SELECT *
FROM jobs_data
GROUP BY ds , job_id , actor_id , event , language , time_spent , org
HAVING COUNT(*) > 1;


# MEASURE THE USER ENGAGEMENT ON WEEKLY BASIS

SELECT 
    COUNT(*) AS engagements,
    WEEKOFYEAR(occurred_at) AS week_of_year,
    YEAR(occurred_at) AS year
FROM (
	SELECT * FROM events_data
    WHERE event_type='engagement'
) AS engagement_events
GROUP BY week_of_year , year;


# ANALYZE THE GROWTH OF USERS OVER TIME OF PRODUCTS

SELECT 
    COUNT(DISTINCT user_id) AS no_of_users_gained,
    device,
    MONTH(occurred_at) AS month,
    YEAR(occurred_at) AS year
FROM events_data
GROUP BY device , month , year;


# ANALYZE THE RETENTION OF USERS ON WEEKLY BASIS FOR A PRODUCT

WITH weekly_users AS (
	SELECT device, 
		COUNT(distinct user_id) AS no_of_users,
		WEEKOFYEAR(occurred_at) AS week_of_year,
		YEAR(occurred_at) AS year
	FROM events_data
	WHERE user_id in (
		SELECT DISTINCT user_id
		FROM new_events
		WHERE event_type = 'signup_flow'
	)
	GROUP BY device, week_of_year, year
)

SELECT 
	device, 
	SUM(no_of_users) 
		OVER(PARTITION BY device ORDER BY week_of_year) 
        AS retained_users,
    week_of_year,
    year 
FROM weekly_users;


# CALCULATE WEEKLY ENGAGEMENT PER DEVICE

SELECT 
    round( COUNT(event_type)/COUNT(DISTINCT device), 2) AS avg_engagements,
    WEEKOFYEAR(occurred_at) AS week_of_year,
    YEAR(occurred_at) AS year
FROM (
	SELECT * FROM events_data
    WHERE event_type='engagement'
) AS engagement_events
GROUP BY week_of_year , year;

# ANALYZE THE USER ENGAGEMENT IN EMAIL SERVICE

SELECT 
    COUNT(DISTINCT user_id) AS no_of_users,
    COUNT(*) AS engagements,
    ROUND(COUNT(*) / COUNT(DISTINCT user_id), 2) AS avg_engagements,
    MONTH(occurred_at) AS month,
    YEAR(occurred_at) AS year
FROM
    mail_events
GROUP BY month , year;







    