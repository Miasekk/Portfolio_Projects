
-- Creation of table, where results from last 3 seasons will be stored
CREATE TABLE last_3_season(
	Season VARCHAR(9), 	
	Year SMALLINT, 	
	Position SMALLINT, 	
	Squad VARCHAR(30), 	
	MP SMALLINT, 	
	W SMALLINT, 	
	D SMALLINT, 	
	L SMALLINT, 	
	GS SMALLINT, 	
	GL SMALLINT, 	
	GD SMALLINT, 	
	Points SMALLINT, 	
	Pts_per_MP DECIMAL, 	
	xGS DECIMAL, 	
	xGL DECIMAL, 	
	xGD DECIMAL, 	
	xGD_per_MP DECIMAL
);


--Importing data regarding last 3 seasons
COPY last_3_season(Season, Year, Position, Squad, MP, W, D, L, GS, GL, GD, Points, Pts_per_MP, xGS,xGL, xGD, xGD_per_MP
)
FROM 'C:\Users\Maciek\AppData\Local\Temp\zcx\teams_3_seasons.csv'
DELIMITER ','
CSV HEADER;

-- Now as I have results data imported into database I am going to create first indicator - "Firepower"
-- For creation this indicator I am going to use weighted average. I am using this measure to do not overlook potential of strong teams with poor season and to no overestimate mediocre teams with exceptional season
-- Firepower indicator is based on gained points per game
-- Due to analysed period, I may have 4 different scenarios so I prepared case statemnt to assign suitable weight to the result depending on seasons in which team participated 
-- Breakdown of variants is illustrated in file "Variants.jpg" in this repository.
-- Evaluated firepower will be saved as View to improve readability of the code, ease of usage for further analysis and accessability for creation of main indicator - Favourable Team Index.


CREATE VIEW firepower AS(
WITH variants AS(
SELECT 
	ls.squad, 
	CASE
		WHEN SUM(ls.year) = 6063 THEN 'Variant 1'
		WHEN SUM(ls.year) = 4043 THEN 'Variant 2'
		WHEN SUM(ls.year) = 4042 THEN 'Variant 3'
		WHEN SUM(ls.year) = 2022 THEN 'Variant 4'
	END AS Variant
FROM 
	last_3_season ls 
	
--filtering by EXISTS to filter out teams, which are not playing in current edition of Premier League
WHERE 
	EXISTS (
					SELECT 
						1 
					FROM 
						last_3_season ls2 
					WHERE 
						ls.squad = ls2.squad AND ls2.year = 2022
	)
GROUP BY 
	ls.squad)
	
-- to estimate firepower I have divided teams into 5 equal size groups
SELECT -- outer query to assign points regarding firepower
	squad,
	variant,
	firepower,
	RANK() OVER(ORDER BY firepower DESC),
	CASE -- descriptive information to ease data exploration later in Tableau
		WHEN RANK() OVER(ORDER BY firepower DESC) < 5 THEN 'Exceptional' 
		WHEN RANK() OVER(ORDER BY firepower DESC) < 9 THEN 'Good'
		WHEN RANK() OVER(ORDER BY firepower DESC) < 13 THEN 'Mediocre'
		WHEN RANK() OVER(ORDER BY firepower DESC) < 17 THEN 'Not Good'
		ELSE 'Weak' END AS strength_level,
	CASE -- Numerical value that will bu used as one of the indicator to establish "Favourable Team Index" indicator.
		WHEN RANK() OVER(ORDER BY firepower DESC) < 5 THEN 3
		WHEN RANK() OVER(ORDER BY firepower DESC) < 9 THEN 2
		WHEN RANK() OVER(ORDER BY firepower DESC) < 13 THEN 1
		WHEN RANK() OVER(ORDER BY firepower DESC) < 17 THEN 0
		ELSE -1 END AS pts
FROM
		(
		SELECT -- inner query to evaluate firepower of teams depending on variant(established at the beginning as CTE)
			squad,
			variant,
			CASE variant -- evaluation of firepower indicator, based on weighted average
				WHEN 'Variant 1' THEN (s3*0.7 + s2* 0.2+ s1*0.1)
				WHEN 'Variant 2' THEN (s3*0.8 + s2* 0.2)
				WHEN 'Variant 3' THEN (s3*0.9 + s1*0.1)
				WHEN 'Variant 4' THEN (s3*1)
			END as firepower

		FROM 
			(
			SELECT -- inner query to pivot the data, the lower number next to the "s" letter, the older the season is
				squad, 
				variant,
				(SELECT pts_per_mp AS s1 FROM last_3_season l3s WHERE season = '2020/2021' AND l3s.squad = v.squad),
				(SELECT pts_per_mp AS s2 FROM last_3_season l3s WHERE season = '2021/2022' AND l3s.squad = v.squad),
				(SELECT pts_per_mp AS s3 FROM last_3_season l3s WHERE season = '2022/2023' AND l3s.squad = v.squad)
			FROM 
				variants v
			) as pivot_season
			
		) as firepower_evaluation
)


--- After calculation of firepower we can evaluate how many fixtures left each team has
--- The more matches ahead, the more chances to score a point until the end of the season
--- For this purpose I have downloaded data from Internet where each teams fixtures were precisely divided into game weeks, what will let us visualize calendar of each team in further analysis
--- Depending on amount of matches to be played I have assigned points from 3 to 0, breaking teams into 4 groups.
--- View regarding amount of fixtures will be created for creation of Favourable Team Index

-- Creation of table, where upcoming fixtures will be stored
CREATE TABLE up_fixtures(
	gw SMALLINT, 	
	home VARCHAR(30), 	
	away VARCHAR(30)	
);


--Importing data regarding upcoming fixtures
COPY up_fixtures(gw, home, away)
FROM 'C:\Users\Maciek\AppData\Local\Temp\zcx\up_fix.csv'
DELIMITER ','
CSV HEADER;

--- First of all I have checked how many different groups will be created basing on matches left

SELECT 
	squad, 
	COUNT(*) as matches_left
FROM 
---Union of home & away teams into one column
	(
		SELECT 
			home as squad 
		FROM 
			up_fixtures
		UNION ALL
		SELECT 
			away 
		FROM 
			up_fixtures
	) as all_fixtures
GROUP BY 
	1

--- 4 different groups appeared, so the 4 different point groups will be created

CREATE VIEW matches_left AS(
SELECT 
	squad, 
	COUNT(*) as matches_left,
	CASE COUNT(*)
		WHEN 9 THEN 3
		WHEN 8 THEN 2
		WHEN 7 THEN 1
		ELSE 0
		END as pts
FROM 
	(
		SELECT 
			home as squad 
		FROM 
			up_fixtures
		UNION ALL
		SELECT 
			away 
		FROM 
			up_fixtures
	) as all_fixtures
GROUP BY 
	1
ORDER BY 
	COUNT(*) DESC
);

--- Now I am going to evaluate average rivals difficulty for each team
--- For this purposes I will use created VIEW for "firepower indicator" to evaluate rival's strength & combine it with table which consists of information regarding upcoming fixtures
--- To evaluate so called "Difficulty Index" I am going to calculate average firepower of rivals
--- Basing on "Difficulty Index" I will divide teams again into 5 groups and assign points accordingly to Difficulty Indicator
--- Result will be saved in view for further purposes


CREATE VIEW matches_difficulties AS(
SELECT 
	team, 
	ROUND(AVG(rival_fp),2) as avg_difficulty,
	CASE 
		WHEN RANK() OVER(ORDER BY ROUND(AVG(rival_fp),2) ASC) < 5 THEN 3
		WHEN RANK() OVER(ORDER BY ROUND(AVG(rival_fp),2) ASC) < 9 THEN 2
		WHEN RANK() OVER(ORDER BY ROUND(AVG(rival_fp),2) ASC) < 13 THEN 1
		WHEN RANK() OVER(ORDER BY ROUND(AVG(rival_fp),2) ASC) < 17 THEN 0
		ELSE -1 END AS pts
FROM
	(
	--- UNION to bring teams into one column regardless if it is home or away game
	SELECT 
		uf.gw,
		uf.home as team, 
		uf.away as rival,
		fp.firepower as rival_fp
	FROM 
		up_fixtures uf
	JOIN
		firepower fp ON uf.away = fp.squad 
	UNION
	SELECT 
		uf.gw,
		uf.away, 
		uf.home,
		fp.firepower
	FROM 
		up_fixtures uf
	JOIN
		firepower fp ON uf.home = fp.squad
	) as up_fixt
GROUP BY 
	team
ORDER BY 
	ROUND(AVG(rival_fp),2)
);

--- The last calculation which will be used in Favourable Team Index will evaluate percentage of matches versus weak defence
--- I have divided teams into 2 groups basing on goal lost per game (glpg)
--- "Weak defence label" was assigned to team who was in the worse half regarding glpg.
--- Later on, basing on upcoming fixtures I have evaluated percantage of games versus weak defences
--- For data driven decision it is significantly important, because goals scored bring the highest amount of points
--- Data was



---CTE to assign level of defence (worse or better)

CREATE VIEW defences_ahead AS(
WITH goal_lost AS( 
SELECT 
	l.squad, 
	l.gl,
	CASE WHEN
		RANK() OVER(ORDER BY l.gl DESC) <= 10 THEN 'Worse Defense'
		ELSE 'Better Defense' END as Defense_status
FROM 
	last_3_season l
where 
	season = '2022/2023'
ORDER BY 
	l.gl  DESC
),
--- CTE to amount of rivals regarding level of defense
Def_divided AS(
	SELECT 
		team, 
		defense_status, 
		COUNT(*) as matches_to_play FROM
			(
			--- UNION to bring teams into one column regardless if it is home or away game
			SELECT 
				uf.gw,
				uf.home as team, 
				uf.away as rival,
				gl.Defense_status
			FROM 
				up_fixtures uf
			JOIN
				goal_lost gl ON uf.away = gl.squad
			UNION
			SELECT 
				uf.gw,
				uf.away, 
				uf.home,
				gl.Defense_status
			FROM 
				up_fixtures uf
			JOIN
				goal_lost gl ON uf.home = gl.squad
			) AS transform_table
	GROUP BY 
		team, 
		defense_status)
--Final query with percantage result & pts assigned
SELECT 
	team,
	ROUND(matches_to_play*100.0/(SELECT SUM(matches_to_play) FROM def_divided dd WHERE dd.team = dd1.team),1) as perc_against_weak,
	CASE 
		WHEN ROUND(matches_to_play*100.0/(SELECT SUM(matches_to_play) FROM def_divided dd WHERE dd.team = dd1.team),1) > 80 THEN 2 
		WHEN ROUND(matches_to_play*100.0/(SELECT SUM(matches_to_play) FROM def_divided dd WHERE dd.team = dd1.team),1) > 60 THEN 1
		WHEN ROUND(matches_to_play*100.0/(SELECT SUM(matches_to_play) FROM def_divided dd WHERE dd.team = dd1.team),1) > 30 THEN 0
	ELSE -1 END AS pts
FROM 
	def_divided dd1
WHERE 
	defense_status = 'Worse Defense'
);


--- Now I have calculated 4 indicators. Each of them is stored in VIEW. 
--- Teams status regarding chosen indicator can be seen in:
--- A) Powerpoint presentation (placed in repository) on 3rd slide
--- B) At Tableau profile. Link placed in Tableu_Data_Story_Link.txt at page called 'Premier League Indicators'

--- FAVOURABLE TEAM INDEX CALCULATION
SELECT 
	team, 
	SUM(pts) as points
FROM(
	SELECT 
		team, 
		pts
	FROM 
		defences_ahead
	UNION ALL
	SELECT 
		squad, 
		pts
	FROM 
		firepower
	UNION ALL
	SELECT 
		squad, 
		pts
	FROM 
		matches_difficulties
	UNION ALL
	SELECT 
		squad, 
		pts
	FROM 
		matches_left
	) AS FTI
GROUP BY 
	1
ORDER BY 
	SUM(pts) DESC
	
--- Favourable Team Index can be seen:
--- A) Powerpoint presentation (placed in repository) on 4th slide
--- B) At Tableau profile. Link placed in Tableu_Data_Story_Link.txt at page called 'Favourable Team Index'
--- Now I have all the data needed to evaluate status of each team
--- "Favourable Team Index" and the rest 4 componential calculations were exported into '.csv' file to enable usage of the data in Tableau



--- Before I will move to the Tableau and selection proccess I will prepare 2 additional datasets
--- The First is schedule for each team to visualize in Tableau how the calendar of each team is going to look like and how difficult game I may expect
--- Additionally I want to see when teams will play 2 matches in 1 gameweek
--- Additionally later I have saved schedule as VIEW. I will need this dataset during selection of goalkeepers below

COPY(
SELECT 
	gw, 
	team,
	rival,
	ROUND(AVG(rival_fp),2) as rival_strength,
	COUNT(*) ---amount of mayches in one gameweek
FROM
	(
	--- UNION to bring teams into one column regardless if it is home or away game
	SELECT 
		uf.gw,
		uf.home as team, 
		uf.away as rival,
		fp.firepower as rival_fp
	FROM 
		up_fixtures uf
	JOIN
		firepower fp ON uf.away = fp.squad
	UNION
	SELECT 
		uf.gw,
		uf.away, 
		uf.home,
		fp.firepower
	FROM 
		up_fixtures uf
	JOIN
		firepower fp ON uf.home = fp.squad
	) as up_fixt
GROUP BY
	1,2,3
) 
TO 'C:\Users\Maciek\AppData\Local\Temp\zcx\schedule.csv'
DELIMITER ','
CSV HEADER;


--- And the last calculation in SQL before we move on is connected with goalkeeper choice
--- Regarding goalkeepers I have decided to adopt different approach in case to save as much money as I can, without losing much quality
--- I want to use 2 goalkeepers and rotate them until the end of game
--- To choose appropriate players I decided to combine each team along and calculate against what level of firepower they are going to play 
--- Later on I checked what team from the pair is going to play versus weaker opponent and this goalkeeper I assigned as picked in 'gk_chosen' column
--- Additionally I added in CTE calculations regarding performance of defense of each team since the beginning of the season, this will be used in Tableau to filter out the weakest defenses
--- further filtering will be done in Tableau by LOD calculations

---CTE to evalute defense performance to a team
WITH gl_lost AS(
SELECT 
	squad, 
	ROUND(AVG(gl*1.0/mp),2) as gl_per_mp
FROM 
	last_3_season 
WHERE
	season = '2022/2023'
GROUP BY 
	squad
)

SELECT 
	t1.gw,
	t1.team, 
	t1.rival_strength,
	t2.team, 
	t2.rival_strength,
	CASE WHEN t1.rival_strength <= t2.rival_strength THEN t1.rival_strength ELSE t2.rival_strength END as Minimum_str, 
	CASE WHEN t1.rival_strength <= t2.rival_strength THEN t1.team ELSE t2.team END as GK_Chosen,
	gl.gl_per_mp
FROM 
	schedule t1 
CROSS JOIN --- CROSS JOIN to combine each possible combination of team
	schedule t2 
LEFT JOIN
	gl_lost gl 
		ON gl.squad = CASE WHEN t1.rival_strength <= t2.rival_strength THEN t1.team ELSE t2.team END
WHERE 
	t1.gw = t2.gw 
	AND 
	t1.team < t2.team  --- condition to avoid doubled values

