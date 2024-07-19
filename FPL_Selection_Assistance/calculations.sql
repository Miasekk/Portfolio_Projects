-- At this project one of the crucial point is divison of defensive strength and offensive strength and on those foundations create suitable indicators.
-- It is crucial, because game works in such a way, that the top teams defenders often doesn't contribute in game points. The same goes with the worst teams. Forwarders from the worst teams can still contribute in points greatly.


-- Creation datasets for the project


-- Results data
-- Importing result data from current and previous season

CREATE TABLE results (
	counter NUMERIC,
	old_id NUMERIC,
    gameweek NUMERIC,
    match_date DATE,
    home_team VARCHAR(50),
    home_xG NUMERIC,
    home_goals INT,
    away_goals INT,
    away_xG NUMERIC,
    away_team VARCHAR(50),
    season VARCHAR(20),
     notes TEXT
);
COPY results (counter, old_id, gameweek, match_date, home_team, home_xG, home_goals, away_goals, away_xG, away_team, season, notes)
FROM 'INDICATE_PATH'
HEADER CSV
DELIMITER ',';


-- Players data
-- Importing player data from FPL site
CREATE TABLE fantasy_football (
	old_id INT,
    id INT,
    name VARCHAR(255),
    position VARCHAR(50),
    team VARCHAR(50),
    status VARCHAR(10),
    now_cost NUMERIC,
    total_points INT,
    selected_by_percent NUMERIC,
    news TEXT,
    minutes INT,
    starts INT,
    points_per_game NUMERIC,
    goals_scored INT,
    expected_goals NUMERIC,
    expected_goals_per_90 NUMERIC,
    expected_goal_involvements NUMERIC,
    expected_goal_involvements_per_90 NUMERIC,
    goals_conceded INT,
    goals_conceded_per_90 NUMERIC,
    expected_goals_conceded NUMERIC,
    expected_goals_conceded_per_90 NUMERIC,
    assists INT,
    expected_assists NUMERIC,
    expected_assists_per_90 NUMERIC,
    yellow_cards INT,
    saves INT,
    saves_per_90 NUMERIC,
    clean_sheets INT,
    clean_sheets_per_90 NUMERIC,
    bonus INT,
    form NUMERIC,
    threat NUMERIC,
    creativity NUMERIC,
    influence NUMERIC,
    penalties_order NUMERIC,
    direct_freekicks_order NUMERIC,
    corners_and_indirect_freekicks_order NUMERIC
);

COPY fantasy_football(old_id,id,name,position,team,status,now_cost,total_points,selected_by_percent,news,minutes,starts,points_per_game,goals_scored,expected_goals,expected_goals_per_90,expected_goal_involvements,expected_goal_involvements_per_90,goals_conceded,goals_conceded_per_90,expected_goals_conceded,expected_goals_conceded_per_90,assists,expected_assists,expected_assists_per_90,yellow_cards,saves,saves_per_90,clean_sheets,clean_sheets_per_90,bonus,form,threat,creativity,influence,penalties_order,direct_freekicks_order,corners_and_indirect_freekicks_order )
FROM 'INDICATE_PATH'
HEADER CSV
DELIMITER ',';


-- Raw data is ready to be digested. From now the target is create indicators, which calculates defence and offence power of each team.
-- Later on, I am going to calculate what kind of average strength awaits for each team in upcoming games
-- Further I will assign to each player the upcoming rivals strengths.


CREATE VIEW upcoming_matches AS

--Pivot one event record data into two records for further calculations

WITH allgames AS(
SELECT 
	home_team, 
	home_goals, 
	home_xG,
	away_goals AS G_conceded,
	away_xg AS xG_conceded,
	season
FROM
	results
WHERE 
	home_goals IS NOT NULL
UNION ALL
SELECT 
	away_team, 
	away_goals, 
	away_xG,
	home_goals AS G_conceded,
	home_xg AS xG_conceded,
	season
FROM
	results
WHERE 
	away_goals IS NOT NULL),


-- Get the list of the teams playing in current season (omit relegated teams)

current_season_teams AS (
SELECT
	DISTINCT(home_team) as team
FROM
	results
WHERE
	season = '2023/2024'
),


-- Calculate goals and expected goals scored and conceded per game. This will be used as Offensive and defensive power indicator, 
-- In addition with information of how many times the team exists in the dataset, the information shows wheter the team played in previous season as well.

seasonsplayed AS(
SELECT
	home_team AS team,
	ROUND(SUM(home_goals)*1.0/COUNT(home_team),2) as goals_scored,
	ROUND(SUM(home_xG*1.0)/COUNT(home_team),2) as xg_scored,
	ROUND(SUM(G_conceded)*1.0/COUNT(home_team),2) AS goals_conceded,
	ROUND(SUM(xG_conceded)*1.0/COUNT(home_team),2) AS xG_conceded,
	season,
	COUNT(*) OVER(PARTITION BY home_team) as seasons_in_pl
FROM 
	allgames
GROUP BY 1,6),


-- Creation of indicators
-- In this part the algorithm slightly favours the true evant data over expected goals (60 : 40).
-- The data is divided into seasons, this will be later used to distinguish fresher data in calculation for further calculation of indicators

pre_indicators AS(
SELECT
	sp.team,
	sp.season,
	sp.goals_scored*0.6+sp.xg_scored*0.4 AS offensive_indicator,
	sp.goals_conceded*0.6+sp.xg_conceded*0.4 AS defensive_indicator,
	seasons_in_pl
FROM
	seasonsplayed sp
where
	sp.team IN(
				SELECT
					team
				FROM
					current_season_teams
	)

),


-- Joining current season offensive and defensive indicators with previous season indicators into one table
pivot	AS (
SELECT 
	pi.team,
	pi.seasons_in_pl,
	pi.offensive_indicator AS OI_2324,
	pi.defensive_indicator AS DI_2324,
	ps.OI_2223 AS OI_2223,
	ps.DI_2223 AS DI_2223
FROM 
	pre_indicators pi
LEFT JOIN
	(
	SELECT 
	team,
	seasons_in_pl,
	offensive_indicator AS OI_2223,
	defensive_indicator AS DI_2223
FROM 
	pre_indicators
WHERE
	season = '2022/2023'
	) as ps
	ON pi.team = ps.team
WHERE
	season = '2023/2024'),


-- Second step in creation of indicators. If team has played in previous season, then take under consideration performance from last year.
-- Ratio is ( 70 : 30 ) in favour of current season
Indicators AS(
SELECT 
team,
	CASE 
		WHEN seasons_in_pl = 2
			THEN ROUND(oi_2324 * 0.7 + oi_2223 * 0.3,3)
		WHEN seasons_in_pl= 1
			THEN ROUND(oi_2324,2)		
		END AS offensive_indicator,
	CASE 
		WHEN seasons_in_pl = 2
			THEN ROUND(di_2324 * 0.7 + di_2223 * 0.3,3)
		WHEN seasons_in_pl = 1
			THEN ROUND(di_2324,2)
		END AS defensive_indicator
FROM 
	pivot),
	

-- Calculate the overall MAX and MIN indicators, divide it into 5 equal ranges.

indicators_range AS(
SELECT
	MAX(offensive_indicator) as off_max,
	ROUND((MAX(offensive_indicator)- MIN(offensive_indicator))/5,3) as off_range,
	MIN(defensive_indicator) AS def_min,
	ROUND((MAX(defensive_indicator)- MIN(defensive_indicator))/5,3) as def_range
FROM 
	Indicators),
	
	
-- Create table with all of the possible ranges for deffensive and offensive indicators via Recursive CTE
-- Assign to each of the range amount of points for standardization (from 3 to -1, step = 1)

indicators_ranking AS(
WITH RECURSIVE comparison (off_max, lower_off, off_range, def_min, higher_def,def_range, n) AS (
  SELECT
    off_max,
	off_max - off_range as lower_off,
    off_range,
    def_min,
	def_min + def_range as higher_def,
    def_range,
    1 as n
  FROM indicators_range
  UNION ALL
  SELECT
    off_max - off_range,
	lower_off - off_range as lower_off,
    off_range,
    def_min + def_range,
	higher_def + def_range as higher_def,
    def_range,
    n + 1
  FROM comparison
  WHERE n < 5
)
SELECT 
	off_max AS upper_off,
	lower_off AS lower_off,
	CASE
		WHEN n = 1 THEN 3
		WHEN n = 2 THEN 2
		WHEN n = 3 THEN 1
		WHEN n = 4 THEN 0
		WHEN n = 5 THEN -1
	END AS off_pts,
	def_min AS lower_def,
	higher_def AS upper_def,
	CASE
		WHEN n = 1 THEN 3
		WHEN n = 2 THEN 2
		WHEN n = 3 THEN 1
		WHEN n = 4 THEN 0
		WHEN n = 5 THEN -1
	END AS def_pts
FROM comparison),


--  Join to each team final offensive and defensive indicator with respective points for these results

team_status AS(
SELECT
	i.team,
	i.offensive_indicator,
	i.defensive_indicator,
	MIN(ir1.off_pts) AS off_pts,
	MIN(ir2.def_pts) AS def_pts
FROM indicators i
LEFT JOIN indicators_ranking ir1
	ON i.offensive_indicator >= ir1.lower_off AND i.offensive_indicator <= ir1.upper_off
LEFT JOIN indicators_ranking ir2
	ON i.defensive_indicator >= ir2.lower_def AND i.defensive_indicator <= ir2.upper_def
GROUP BY 
	i.team,
	i.offensive_indicator,
	i.defensive_indicator)


-- Calculate how the each team situation looks like in chosen by user gameweek. 
-- In inner queries I am firstly calculating strength of the single rival. LAter on thanks to the Window Functions I am evaluating upcoming games in 3 different perspective
-- At the end I am collecting it alltogether and translating the result into description, dividing fixtures into 4 groups ['Terrible fixtures', 'Tough fixtures', 'Good fixtures', 'Great fixtures']
-- The last operation will make the data more readable at the charts.

SELECT
		gameweek,
		match_date,
		home_team AS team,
		off_power,
		def_power,
		side, 
		rival_off_power,
		rival_def_power,
		rival_off_pts,
		rival_def_pts,
		rivals_def_short_term,
		RANK() OVER (PARTITION BY gameweek ORDER BY rivals_def_short_term DESC) AS rivals_short_term_def_rank,
		CASE 
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_def_short_term DESC) >= 16 THEN 'Terrible fixtures'
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_def_short_term DESC) >= 11 THEN 'Tough fixtures'
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_def_short_term DESC) >= 6 THEN 'Good fixtures'
			ELSE 'Great fixtures' END AS rivals_def_short_term_fixtures,
		rivals_def_mid_term,
		RANK() OVER (PARTITION BY gameweek ORDER BY rivals_def_mid_term DESC) AS rivals_mid_term_def_rank,
		CASE 
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_def_mid_term DESC) >= 16 THEN 'Terrible fixtures'
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_def_mid_term DESC) >= 11 THEN 'Tough fixtures'
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_def_mid_term DESC) >= 6 THEN 'Good fixtures'
			ELSE 'Great fixtures' END AS rivals_def_mid_term_fixtures,
		rivals_def_long_term,
		RANK() OVER (PARTITION BY gameweek ORDER BY rivals_def_long_term DESC) AS rivals_long_term_def_rank,
		CASE 
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_def_long_term DESC) >= 16 THEN 'Terrible fixtures'
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_def_long_term DESC) >= 11 THEN 'Tough fixtures'
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_def_long_term DESC) >= 6 THEN 'Good fixtures'
			ELSE 'Great fixtures' END AS rivals_def_long_term_fixtures,
		rivals_off_short_term,
		RANK() OVER (PARTITION BY gameweek ORDER BY rivals_off_short_term ASC) AS rivals_short_term_off_rank,
		CASE 
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_off_short_term ASC) >= 16 THEN 'Terrible fixtures'
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_off_short_term ASC) >= 11 THEN 'Tough fixtures'
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_off_short_term ASC) >= 6 THEN 'Good fixtures'
			ELSE 'Great fixtures' END AS rivals_off_short_term_fixtures,
		rivals_off_mid_term,
		RANK() OVER (PARTITION BY gameweek ORDER BY rivals_off_mid_term ASC) AS rivals_mid_term_off_rank,
		CASE 
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_off_mid_term ASC) >= 16 THEN 'Terrible fixtures'
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_off_mid_term ASC) >= 11 THEN 'Tough fixtures'
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_off_mid_term ASC) >= 6 THEN 'Good fixtures'
			ELSE 'Great fixtures' END AS rivals_off_mid_term_fixtures,
		rivals_off_long_term,
		RANK() OVER (PARTITION BY gameweek ORDER BY rivals_off_long_term ASC) AS rivals_long_term_off_rank,
		CASE 
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_off_long_term ASC) >= 16 THEN 'Terrible fixtures'
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_off_long_term ASC) >= 11 THEN 'Tough fixtures'
			WHEN RANK() OVER (PARTITION BY gameweek ORDER BY rivals_off_long_term ASC) >= 6 THEN 'Good fixtures'
			ELSE 'Great fixtures' END AS rivals_off_long_term_fixtures

FROM (
	SELECT -- Calculate toughness of upcoming games from short/mid/long term perspective
		gameweek,
		match_date,
		home_team,
		off_power,
		def_power,
		side, rival_off_power,
		rival_def_power,
		rival_off_pts,
		rival_def_pts,
		ROUND(AVG(rival_def_power) OVER(PARTITION BY home_team ORDER BY match_date ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING),2) AS rivals_def_short_term,
		ROUND(AVG(rival_def_power) OVER(PARTITION BY home_team ORDER BY match_date ROWS BETWEEN CURRENT ROW AND 5 FOLLOWING),2) AS rivals_def_mid_term,	
		ROUND(AVG(rival_def_power) OVER(PARTITION BY home_team ORDER BY match_date ROWS BETWEEN CURRENT ROW AND 7 FOLLOWING),2) AS rivals_def_long_term,
		ROUND(AVG(rival_off_power) OVER(PARTITION BY home_team ORDER BY match_date ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING),2) AS rivals_off_short_term,
		ROUND(AVG(rival_off_power) OVER(PARTITION BY home_team ORDER BY match_date ROWS BETWEEN CURRENT ROW AND 5 FOLLOWING),2) AS rivals_off_mid_term,	
		ROUND(AVG(rival_off_power) OVER(PARTITION BY home_team ORDER BY match_date ROWS BETWEEN CURRENT ROW AND 7 FOLLOWING),2) AS rivals_off_long_term

	FROM
		(
		SELECT -- Evaluation of each team rivals strength in each gameweek. Using home-team advantage to increase/decrease strrength of rival
			r.gameweek, 
			r.match_date,
			r.home_team, 
			ts2.offensive_indicator AS off_power, 
			ts2.defensive_indicator AS def_power,  
			'Home' AS side, 
			r.away_team as rival,
			ROUND(ts.offensive_indicator*0.93,2) AS rival_off_power, 
			ROUND(ts.defensive_indicator*0.93,2) AS rival_def_power,  
			ts.off_pts AS rival_off_pts,
			ts.def_pts AS rival_def_pts
		FROM 
			results r
		LEFT JOIN team_status ts
			ON 
			r.away_team = ts.team
		LEFT JOIN team_status ts2
			ON 
			r.home_team = ts2.team
		WHERE 
			home_goals IS NULL
		UNION ALL
		SELECT 
			r.gameweek, 
			r.match_date,
			r.away_team, 
			ts2.offensive_indicator AS off_power, 
			ts2.defensive_indicator AS def_power,
			'Away', 
			r.home_team as rival,
			ROUND(ts.offensive_indicator*1.07,2) AS rival_off_power, 
			ROUND(ts.defensive_indicator*1.07,2) AS rival_def_power,  
			ts.off_pts AS rival_off_pts,
			ts.def_pts AS rival_def_pts
		FROM 
			results r
		LEFT JOIN team_status ts
			ON 
			r.home_team = ts.team
		LEFT JOIN team_status ts2
			ON 
			r.away_team = ts2.team
		WHERE 
			home_goals IS NULL
		ORDER BY gameweek ASC
	) as all_fixtures
) AS calendar_extended



-- As the result of the previous query we have information of each team offensive and defensive strength, calculated by taking into consideration expected results and true results. 
-- Additionally we took under consideration previous season and current form to create those synthetic indicators.


-- Now basing on player data (significant from FPL game point of view) I am going to highlight the players that I already have, to distunguish them at charts and see how they perform at the ground of the other players at the same position.
-- This data is modified manually each week.

CREATE OR REPLACE VIEW my_team AS (
SELECT 
	name,
	position,
	team,
	mt As my_team
FROM(
	SELECT 
		name, 
		position, 
		team, 
		CASE 
			WHEN CONCAT(name,' ', position,' ', team) IN(

		-- Goalkeepers
		'Jordan Pickford GKP Everton',
		'Matt Turner GKP Nott''ham Forest',

		-- Defenders
		'Gabriel dos Santos Magalhães DEF Arsenal',
		'Levi Colwill DEF Chelsea',
		'Jordan Beyer DEF Burnley',
		'Pedro Porro DEF Tottenham',
		'Konstantinos Tsimikas DEF Liverpool',

		-- Midfielders
		'Martin Ødegaard MID Arsenal',
		'Bukayo Saka MID Arsenal',
		'Cole Palmer MID Chelsea',
		'Phil Foden MID Manchester City',
		'Richarlison de Andrade MID Tottenham',

		-- Forwarders
		'Julián Álvarez FWD Manchester City',
		'Ollie Watkins FWD Aston Villa',
		'Divin Mubama FWD West Ham'
		)
		 Then True Else False END as mt
	FROM 
		fantasy_football ff
) AS inq
WHERE mt IS True
);


-- Combine player data with the upcoming rivals strength and with addition wheter the player is already in my team

CREATE VIEW players_fpl AS
SELECT 
	old_id,
	id,
	ff.name,
	ff.position,
	ff.team,
	status,
	now_cost,
	total_points,
	selected_by_percent,
	news,
	minutes,
	starts,
	points_per_game,
	goals_scored,
	expected_goals,
	expected_goals_per_90,
	expected_goal_involvements,
	expected_goal_involvements_per_90,
	goals_conceded,
	goals_conceded_per_90,
	expected_goals_conceded,
	expected_goals_conceded_per_90,
	assists,
	expected_assists,
	expected_assists_per_90,
	yellow_cards,
	saves,
	saves_per_90,
	clean_sheets,
	clean_sheets_per_90,
	bonus,
	form,
	threat,
	creativity,
	influence,
	penalties_order,
	direct_freekicks_order,
	corners_and_indirect_freekicks_order,
	(SELECT MIN(gameweek) FROM upcoming_matches) AS current_GW,
	rival_off_power,
	rival_def_power,
	rival_off_pts,
	rival_def_pts,
	rivals_def_short_term,
	rivals_short_term_def_rank,
	rivals_def_short_term_fixtures,
	rivals_def_mid_term,
	rivals_mid_term_def_rank,
	rivals_def_mid_term_fixtures,
	rivals_def_long_term,
	rivals_long_term_def_rank,
	rivals_def_long_term_fixtures,
	rivals_off_short_term,
	rivals_short_term_off_rank,
	rivals_off_short_term_fixtures,
	rivals_off_mid_term,
	rivals_mid_term_off_rank,
	rivals_off_mid_term_fixtures,
	rivals_off_long_term,
	rivals_long_term_off_rank,
	rivals_off_long_term_fixtures,
	mt.my_team
	
FROM 
	fantasy_football ff
LEFT JOIN
	upcoming_matches uc ON
		ff.team = uc.team AND (SELECT MIN(gameweek) FROM upcoming_matches) = uc.gameweek 
LEFT JOIN
	my_team mt ON 
		ff.name = mt.name AND ff.team = mt.team AND ff.position = mt.position



