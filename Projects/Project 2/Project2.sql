#AFTER THE INSERTING THE GIVEN DATA

USE ig_clone;

# FINDING THE 5 OLDEST USERS

SELECT sl_no, id, username, created_at
FROM (
	SELECT *, RANK() OVER( ORDER BY created_at ) AS sl_no
	FROM users 
) as ranked_table
WHERE sl_no<=5;


# IDENTITYFING INACTIVE USERS

SELECT id, username
FROM users
WHERE id NOT IN (
	SELECT DISTINCT user_id
	FROM photos
);


# DETERMINING THE MOST LIKED POST

WITH likes_count AS (
	SELECT photo_id, COUNT(user_id) AS no_of_likes
	FROM likes
	GROUP BY photo_id
)

, max_liked AS (
	SELECT user_id, photo_id, no_of_likes
	FROM likes_count
	INNER JOIN photos 
	ON likes_count.photo_id = photos.id
	AND no_of_likes = (SELECT MAX(no_of_likes) FROM likes_count)
)

SELECT id, username, max_liked.photo_id, max_liked.no_of_likes
FROM users
INNER JOIN max_liked 
ON users.id = max_liked.user_id;


# IDENTIFYING THE 5 MOST POPULAR HASHTAGS

WITH hashtags AS (
	SELECT tag_id, COUNT(*) AS tag_count
	FROM photo_tags
	GROUP BY tag_id
)

SELECT sl_no, tag_id, tag_name, tag_count 
FROM (
	SELECT *, RANK() OVER(ORDER BY tag_count DESC) AS sl_no
	FROM hashtags
	INNER JOIN tags 
	ON tags.id=hashtags.tag_id
) AS most_popular
WHERE sl_no<=5;


# DETERMINING THE DAY OF WEEK WHEN MOST USERS REGISTERED

WITH day_count_table AS (
	SELECT DAYOFWEEK(created_at) AS day_of_week, COUNT(*) AS day_count
	FROM users
	GROUP BY day_of_week
    ORDER BY day_of_week
)

SELECT * 
FROM day_count_table
WHERE day_count=( SELECT MAX(day_count) FROM day_count_table );


# CALCULATING AVG POSTS PER USER

SELECT 
    ROUND(COUNT(*) / COUNT(DISTINCT user_id), 3) AS active_users_avg,
    ROUND(COUNT(*) / (SELECT COUNT(id) FROM users), 3) AS total_users_avg
FROM
    photos;


# IDENTIFYING BOT ACCOUNTS 

WITH liked_table AS (
	SELECT user_id, COUNT(user_id) AS liked_count
    FROM likes
	GROUP BY user_id
)

SELECT 
    id AS user_id, username AS bot_accounts
FROM users
INNER JOIN liked_table 
ON users.id = liked_table.user_id
WHERE liked_count = (SELECT COUNT(*) FROM photos);



