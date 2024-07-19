Hello,

The repository you are discovering right now is connected with my portoflio project.

-------- Preface

The project is connected with worldwide game called “Fantasy Premier League”. Below I present abstract of the game rules, for further reference I am adding link to official site, with all of the information.

In the game each manager has limited budget, for which one can buy players with some limitations. Later on, basing on a performance in real matches they are gaining or losing points. At the end of the gameweek, points gathered by starting line-up are summed up and translated into the gameweek / global ranking with real prizes to collect. Transfers amount are limited so there are multiple factors which needs considered before making the transfer. 

In the past I have created one project regarding this game. Link: https://github.com/Miasekk/Portfolio_Projects/tree/main/FPL_DataDrivDecision
My previous project has been launched at the finish of the season with the main goal - to beat the ranking position of my friend. However, the approach, where the selection was highly connected with data paid off, so I wanted to start next season with the upgraded tool and the same approach – decisions based on data.

To better understand that the game is about I highly recommend visiting those sites, where everything is written clear:
https://www.premierleague.com/news/2173986
https://fantasy.premierleague.com/help




-------- Why I launched this project

I am describing myself as a competitive football-enthusiast, so whenever I am doing something, I am making sure that whatever I have done, I have had done enough to finish something with the best possible outcome. So when I am making choices in “Fantasy Premier League” I want to make best possible decision. However, without the digging into data it comes to “gut feeling”, with pretty shallow real data (such as news, upcoming rival) to back the decision. 

This time I wanted to change things a little bit, due to 4 major facts:
-	I spent too much time to to made/change strategy (going through some pages, news, previous history, etc. takes a lot of time),
-	I have made huge incline in ranking, thanks to data driven decision approach last year,
-	It was always tough to distinguish best option among 3 – 4 possibilities
-	I didn’t have a tool to manage my long-term, strategic plans.

However, I still wanted to make fun out of the game, so I didn’t want any algorithm to decide what to do, I wanted to get all the needed information from underlying data, to accelerate the process of deciding what steps should I make.
To make it possible, I have decided to create semi-automated report in Tableau, which let me swiftly:
-	Evaluate teams offensive power (recalculated after each gameweek),
-	Evaluate teams defensive power (recalculated after each gameweek),
-	Measure key player metrics,
-	Find quality players, not used by the community (so-called differentials),
-	Compare stats of up to 4 players at once,
-	Explore suspension risks,
-	Define difficulty of the calendar for a team in upcoming 2, 5 or 7 matches for specified period of time





-------- Goals of the project

At the time of writing the documentation, the season is over, so I am able to distinguish what I managed to achieve, and what didn’t go as I imagined.
* Realized goals
- Reducing time spent in the game (tough to calculate but that was huge upside, there were many weeks when I spent 5 minutes between two gamewweks)
- Beating my previous score (my previous record was being among top 17% managers, after this season my PB is being among top 2% of managers) 


* Not realized goals
- Winning mini-league created by me and my 10 friends (finished second)




-------- Final product 

Semi-automated report in Tableau, which let me rapidly:
-	Evaluate teams offensive power (recalculated after each gameweek),
-	Evaluate teams defensive power (recalculated after each gameweek),
-	Measure key player metrics,
-	Find quality players, not used by the community (so called differentials),
-	Compare up to 4 players at once,
-	Explore suspension risks,
-	Define difficulty of the calendar for a team in upcoming 3, 5 or 7 matches for specified period of time




-------- Indicators used to create the final product

At this project I wanted to distinguish teams into two seperate dimension - offensive and defensive strength. At top of that I wanted to created indicators based on my ideas how to assign proper score to a team.
Indicators takes under consideration:
- Current season form
- Previous season performance
- True outcome of played matches
- Expected outcome of played outcome
- Home team advantage




-------- Tools used

1.  Python
	* Data scraping & copying
	* Data cleaning & remodelling
	* Automatization
2. PostgresQL
	* Data aggregation
	* Data Exploration
	* Analysis of the data and creation of indicators
	* Creation of final datasets
3. Tableau
	* Data visualization
	* Data exploration
	* Further data aggregation through calculated fields
	* Combination of data into interactive, easy to follow dashboard
4. Excel
	* Adhoc analysis



-------- Elements of the project placed in this repository

1.	Readme.txt
Preface to the project, which u are reading right now

2.	Gather_resources.py
Python script, which copies/scrapes data from the Internet which is used to get the raw csv files, used later in SQL.
As the effect of the script 4 csv files are being created:
-  players_fbref.csv
-  fantasy-premier-league-2024/players.csv
-  calendar_22_23.csv
-  Matches_and_results.csv

3. 	Calculations.sql
Code produces ultimate datasets with synthetic indicators. Later on data is imported into Tableau.



-------- How the system works

Whole workflow executed before each gameweek: 
1. Booting the python script to refresh raw files.
2. Truncating "results" and "fantasy_football" tables in SQL and copying fresh data into those tables
3. Actualizing the view "my_team", which consists of my squad (if needed) 
4. Executing "players_fpl" and "upcoming_matches" queries and saving queries result at the defined path (path used by Tableau to connect to data sources)
5. Refreshing the data in Tableau

All done, dashboard is ready to be explored