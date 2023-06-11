-- After importing excel file "TOP1000_IMDB.xlsm" into database I wanted to answet six questions and later on visualize them in Tableau. 

-- I splitted the questions into 2 different categories, actors/actresses and directors/directress
-- Following questions will be answered during further analysis
-- 1.	What actors/actresses played in highest amount of top movies so far?
-- 2.	What pairs of actors/actresses brought togehter the highest amount of best movies?
-- 3.	Who is the most versatile actor/actress? (with how many different directors they managed to produce top class movies)
-- 4.	Who directed the highest amount of top movies so far?
-- 5.	What is the best collaboration of director & actor?
-- 6.	What directors/directress have involved the highest amount of various movie genres?

--First of all I wanted to make sure that all of my records were rated by significant amount of votes. The number what I chose is at least 20 000 votes

DELETE 
FROM 
	movies 
WHERE 
	no_of_votes < 20000
	


-- Now I am going to answer the first question
-- 1.	What actors/actresses played in highest amount of top movies so far?


-- Main actors of each movie are placed in 4 different columns, due to this fact I need to union them all in one column, what is done i CTE called "act"

WITH act AS 
(
	SELECT 
 	star1 as star 
FROM 
 	movies
UNION ALL
SELECT 
 	star2 
 FROM  
 	movies
UNION ALL
SELECT 
 	star3 
 FROM  
 	movies
UNION ALL
SELECT 
 	star4 
 FROM  
 	movies
)

-- Now I can perform simple grouping with filtering at the end to limit results to the amount, which won't affect negatively at readability of Tableau visualization

SELECT 
	star, 
	COUNT(*) as movies
FROM 
	act
GROUP BY 
	star
HAVING 
	COUNT(*) >= 9 -- limitation to 15 actor/actresses
ORDER BY 
	COUNT(*) DESC

-- The result has been copied and pasted directly into Tableau as on of the data sources.




-- Second question
-- 2.	What pairs of actors/actresses brought togehter the highest amount of best movies?

-- In this step I would like to check what duet of actors/actresses have been the most succesful
-- Dataset has actors/actess placed in 4 different columns, called "star1", "star2", etc. So the data need to be modified in order to use it for mentioned purposes

-- Firstly, I have reduced amount of columns with starts into one column called "star" by using UNION function. Result was wrapped into CTE

WITH allstars AS
(SELECT 
 	star1 as star 
FROM 
 	movies
UNION
SELECT 
 	star2 
 FROM  
 	movies
UNION
SELECT 
 	star3 
 FROM  
 	movies
UNION
SELECT 
 	star4 
 FROM  
 	movies
),

-- Now i Have to combine actors/actresses altogether. I used CROSS JOIN funtionality and later on by where clause I wanted to avoid dupliacted rows. Result was wrapped in CTE

actors AS(
SELECT 
	as1.star as star1, 
	as2.star as star2
from 
	allstars as as1
CROSS JOIN allstars as2
WHERE
	as1.star <> as2.star 
		AND 
	as1.star > as2.star 
)

-- Thanks to steps above I have right now CTE with each possible combination of actor/actress
-- So my last step will take each pair and check wheter the pair of stars had an opportunity to play with each other and if yes - how many times?

-- 1st subquery serves as filter to show combination of pairs which were engaged in creation of each movie
-- 2nd subquery counts in how many top movies each pair has been worked together
-- Outer query shrinks the data results to smaller amount of records by using STRING AGG what avoid duplication of records -> It is going to be useful during visualization
-- After first execution of query I noticed that Harry potter's trio took 3 top spots, so I made an exception and left only one record which name will be aliased in visualization
-- At the end I fitlered only duo's who were working with each other in top productions at least 3 times


Select --outer query
	star1 as Star, 
	STRING_AGG(star2,', ') AS Stars,
	movies 
FROM
(
	SELECT --2nd subquery
		star1, 
		star2, 
		COUNT(*) as Movies
	FROM
	(
		SELECT --1st subquery
			t1.title, 
			t2.star1, 
			t2.star2
		from 
			movies t1
		JOIN 
			actors t2 
			ON 
			(t2.star1 = t1.star1 OR t2.star1 = t1.star2 OR t2.star1 = t1.star3 OR t2.star1 = t1.star4)
				AND
			(t2.star2 = t1.star1 OR t2.star2 = t1.star2 OR t2.star2 = t1.star3 OR t2.star2 = t1.star4)
		) as combinations
	WHERE -- In initial results table first 3 places were assigned to combination of Harry Potter's main characters. Due to uniqueness of situation I will leave 1 row with information
		star1 <> 'Emma Watson' AND star2 <> 'Emma Watson' 
	GROUP BY 
		star1, star2
	HAVING
		COUNT(*) >= 3
	ORDER BY 
		COUNT(*) DESC
	) as actors_grouped
GROUP BY 
	Star1,Movies
ORDER BY 
	movies DESC

-- The result has been copied and pasted directly into Tableau as on of the data sources.



-- 3rd question
-- 3.	Who is the most versatile actor/actress? (with how many different directors they managed to produce top class movies)

-- Firstly, I have reduced amount of columns to 2 column, which consists of director of movie and actor by using UNION function. Result was wrapped into CTE
-- 1st subquery is used to avoid row duplication for same collaboration of actor & director in different movies

WITH dir_act AS
(SELECT 
 	director, 
 	star1 as star 
FROM 
 	movies
UNION ALL
SELECT 
 	director,
 	star2 
 FROM  
 	movies
UNION ALL
SELECT 
 	director,
 	star3 
 FROM  
 	movies
UNION ALL
SELECT 
 	director,
 	star4 
 FROM  
 	movies
)
SELECT 
	star, 
	COUNT(*) as different_directors
FROM
	( --1st subquery
	SELECT 
		director, 
		star, 
		COUNT(*) 
	FROM 
		dir_act
	GROUP BY
		director,
		star
	) as anti_duplication
GROUP BY 
	star
HAVING
	COUNT (*) >= 7 -- limiting amount of records to the most significant
ORDER BY
	COUNT(*) DESC

-- The result has been copied and pasted directly into Tableau as on of the data sources.




-- 4th question
-- 4.	Who directed the highest amount of top movies so far?

SELECT 
	director, 
	COUNT(*) as movies
FROM 
	movies
GROUP BY 
	director
HAVING
	COUNT (*) >= 7 -- limiting amount of records to the most significant
ORDER BY 
	COUNT(*) DESC

-- The result has been copied and pasted directly into Tableau as on of the data sources.




-- 5th question
-- 5. What is the best collaboration of director & actor?

-- Firstly, I have reduced amount of columns to 2 column, which consists of director of movie and actor by using UNION function. Result was wrapped into CTE. The same operation was performed to answer 3rd question

WITH dir_act AS
(SELECT 
 	director, 
 	star1 as star 
FROM 
 	movies
UNION ALL
SELECT 
 	director,
 	star2 
 FROM  
 	movies
UNION ALL
SELECT 
 	director,
 	star3 
 FROM  
 	movies
UNION ALL
SELECT 
 	director,
 	star4 
 FROM  
 	movies
)

SELECT 
	director, 
	star, 
	COUNT(*) as amount_of_movies
FROM 
	dir_act
GROUP BY
	director,
	star
HAVING
	COUNT(*) >= 4 --- limiting amount of records to the most significant 
ORDER BY
	COUNT(*) DESC

-- The result has been copied and pasted directly into Tableau as on of the data sources.


-- 6th question
-- 6. What directors/directress have involved the highest amount of various movie genres?

SELECT 
	director, 
	COUNT(*) as Genres
FROM
	(
	SELECT 
		director, 
		genre1 as genre
	FROM 
		movies 
	WHERE 
		genre1 IS NOT NULL
	UNION
	SELECT 
		director, 
		genre2 
	FROM 
		movies 
	WHERE 
		genre2 IS NOT NULL
	UNION
	SELECT 
		director, 
		genre3 
	FROM 
		movies 
	WHERE 
		genre3 IS NOT NULL
	) as genres
GROUP BY 
	director
HAVING
	COUNT(*) >= 8
ORDER BY 
	COUNT(*) DESC;

-- The result has been copied and pasted directly into Tableau as on of the data sources.

