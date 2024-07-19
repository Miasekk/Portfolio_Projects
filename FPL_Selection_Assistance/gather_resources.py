### The script below is used to get the 4 raw csv files with data from 2 different sites (fbref.com & kaggle.com), which later is going to be transformed by SQL codes for further insights
### Script is divided into 4 functions, which are called at the end of the code

# Importing needed libraries
import pandas as pd
import opendatasets as od
import os
import math
import numpy as np


# Function to get the multiple significant player statistics from fbref.com
# The function consists of repetitve operations for different data types. Site has different place for data connected with passing actions, shooting actions, goalkeeping actions etc.

def fbref_player_stats():
    ### Basic statistics
    # link to the data
    url_df = 'https://fbref.com/en/comps/Big5/stats/players/Premier-League-Stats'
    df = pd.read_html(url_df)[0]

    # table has multiple indexes at axis=1, we need to get rid of it. If the columns are multi-indexed, then concatenate it into one string
    df.columns = [' '.join(col).strip() for col in df.columns]
    df = df.reset_index(drop=True)

    # after this operation each column has now index value. However if some of the columns didn't have multiple index, then it has prefix with "level_0" information. 
    # we need to recreate the table with new column names. Single-indexed columns had only one word, so we can grab just the last word from the new column name
    new_columns = []
    for col in df.columns:
        if 'level_0' in col:
            new_col = col.split()[-1]  # takes the last name
        else:
            new_col = col
        new_columns.append(new_col)

    # rename columns
    df.columns = new_columns
    
    df = df.fillna(0)

    ### data cleaning
    # creating copy of the df - will be used to concatenate data altogether
    engdf_stats = df[df['Comp'] == "eng Premier League"]
    # taking only important data,
    engdf_stats = engdf_stats[[ "Player", "Nation", "Pos", "Squad", "Age", "Playing Time Starts", "Playing Time 90s", "Performance Gls", "Performance Ast", "Performance G+A", "Performance PK", "Performance PKatt", "Performance CrdY", "Expected xG", "Expected xAG", "Expected npxG+xAG", "Per 90 Minutes Gls", "Per 90 Minutes Ast", "Per 90 Minutes G+A", "Per 90 Minutes xG", "Per 90 Minutes xAG", "Per 90 Minutes xG+xAG" ]]
    # creating new valuable columns
    engdf_stats['Expected xG+xAG'] = pd.to_numeric(engdf_stats['Expected xG'], errors='coerce') + pd.to_numeric(engdf_stats['Expected xAG'], errors='coerce')
    engdf_stats['G-xG'] = pd.to_numeric(engdf_stats['Performance Gls'], errors='coerce') - pd.to_numeric(engdf_stats['Expected xG'], errors='coerce')



    ### Goalkeepers statistics
    # link to the data
    url_df = 'https://fbref.com/en/comps/Big5/keepers/players/Big-5-European-Leagues-Stats'
    df = pd.read_html(url_df)[0]

    # table has multiple indexes at axis=1, we need to get rid of it. If the columns are multi-indexed, then concatenate it into one string
    df.columns = [' '.join(col).strip() for col in df.columns]
    df = df.reset_index(drop=True)

    # after this operation each column has now index value. However if some of the columns didn't have multiple index, then it has prefix with "level_0" information. 
    # we need to recreate the table with new column names. Single-indexed columns had only one word, so we can grab just the last word from the new column name
    new_columns = []
    for col in df.columns:
        if 'level_0' in col:
            new_col = col.split()[-1]  # takes the last name
        else:
            new_col = col
        new_columns.append(new_col)

    # rename columns
    df.columns = new_columns

    ### data cleaning
    df = df.fillna(0)
    engdf_gk = df[df['Comp'] == "eng Premier League"]
    engdf_gk = engdf_gk[[ "Player", "Nation", "Pos", "Squad", "Age", "Performance GA", "Performance GA90", "Performance SoTA", "Performance Saves", "Performance Save%", "Performance CS%" ]]

    ### merging the data altogether
    df_final = pd.merge(engdf_stats, engdf_gk, how="left", left_on=["Player", "Nation", "Pos", "Squad", "Age"], right_on=["Player", "Nation", "Pos", "Squad", "Age"])


    ### Playingtime statistics
    # link to the data
    url_df = 'https://fbref.com/en/comps/Big5/playingtime/players/Big-5-European-Leagues-Stats'
    df = pd.read_html(url_df)[0]

    # table has multiple indexes at axis=1, we need to get rid of it. If the columns are multi-indexed, then concatenate it into one string
    df.columns = [' '.join(col).strip() for col in df.columns]
    df = df.reset_index(drop=True)

    # after this operation each column has now index value. However if some of the columns didn't have multiple index, then it has prefix with "level_0" information. 
    # we need to recreate the table with new column names. Single-indexed columns had only one word, so we can grab just the last word from the new column name
    new_columns = []
    for col in df.columns:
        if 'level_0' in col:
            new_col = col.split()[-1]  # takes the last name
        else:
            new_col = col
        new_columns.append(new_col)

    # rename columns
    df.columns = new_columns

    ### data cleaning
    df = df.fillna(0)
    engdf_mp = df[df['Comp'] == "eng Premier League"]
    engdf_mp = engdf_mp[[ "Player", "Nation", "Pos", "Squad", "Age", "Playing Time Mn/MP", "Playing Time Min%", "Starts Starts", "Starts Mn/Start", "Team Success onG", "Team Success onGA", "Team Success +/-90", "Team Success (xG) onxG", "Team Success (xG) onxGA", "Team Success (xG) xG+/-90" ]]

    ### merging the data altogether
    df_final = pd.merge(df_final, engdf_mp, how="left", left_on=["Player", "Nation", "Pos", "Squad", "Age"], right_on=["Player", "Nation", "Pos", "Squad", "Age"])


    ### Passing statistics
    # link to the data
    url_df = 'https://fbref.com/en/comps/Big5/passing/players/Big-5-European-Leagues-Stats'
    df = pd.read_html(url_df)[0]

    # table has multiple indexes at axis=1, we need to get rid of it. If the columns are multi-indexed, then concatenate it into one string
    df.columns = [' '.join(col).strip() for col in df.columns]
    df = df.reset_index(drop=True)

    # after this operation each column has now index value. However if some of the columns didn't have multiple index, then it has prefix with "level_0" information. 
    # we need to recreate the table with new column names. Single-indexed columns had only one word, so we can grab just the last word from the new column name
    new_columns = []
    for col in df.columns:
        if 'level_0' in col:
            new_col = col.split()[-1]  # takes the last name
        else:
            new_col = col
        new_columns.append(new_col)

    # rename columns
    df.columns = new_columns

    ### data cleaning
    df = df.fillna(0)
    engdf_pass = df[df['Comp'] == "eng Premier League"]
    engdf_pass = engdf_pass[[ "Player", "Nation", "Pos", "Squad", "Age", "KP", "1/3", "PPA", "CrsPA" ]]
    
    ### merging the data altogether
    df_final = pd.merge(df_final, engdf_pass, how="left", left_on=["Player", "Nation", "Pos", "Squad", "Age"], right_on=["Player", "Nation", "Pos", "Squad", "Age"])

    ### Possesion statistics
    # link to the data
    url_df = 'https://fbref.com/en/comps/Big5/possession/players/Big-5-European-Leagues-Stats'
    df = pd.read_html(url_df)[0]

    # table has multiple indexes at axis=1, we need to get rid of it. If the columns are multi-indexed, then concatenate it into one string
    df.columns = [' '.join(col).strip() for col in df.columns]
    df = df.reset_index(drop=True)

    # after this operation each column has now index value. However if some of the columns didn't have multiple index, then it has prefix with "level_0" information. 
    # we need to recreate the table with new column names. Single-indexed columns had only one word, so we can grab just the last word from the new column name
    new_columns = []
    for col in df.columns:
        if 'level_0' in col:
            new_col = col.split()[-1]  # takes the last name
        else:
            new_col = col
        new_columns.append(new_col)

    # rename columns
    df.columns = new_columns
    df = df.fillna(0)

    ### data cleaning
    engdf_possesion = df[df['Comp'] == "eng Premier League"]
    engdf_possesion = engdf_possesion[[ "Player", "Nation", "Pos", "Squad", "Age", "Touches Att 3rd", "Carries CPA" ]]
    
    ### merging the data altogether
    df_final = pd.merge(df_final, engdf_possesion, how="left", left_on=["Player", "Nation", "Pos", "Squad", "Age"], right_on=["Player", "Nation", "Pos", "Squad", "Age"])

    ### final dataset cleaning
    df_final.rename(columns={ "Pos": "Position", "Playing Time 90s": "Matches playes", "Performance Gls": "Goals", "Performance Ast": "Assists", "Performance G+A": "Goals + Assists", "Performance PK": "Penalties scored", "Performance PKatt": "Penalties attempted", "Performance CrdY": "Yellow Cards", "Expected xG": "xGoals", "Expected xAG": "xAssists", "Expected npxG+xAG": "non pen xG + xAG", "Per 90 Minutes Gls": "Goals per 90min", "Per 90 Minutes Ast": "Assists per 90min", "Per 90 Minutes G+A": "Goals + Assists per 90min", "Per 90 Minutes xG": "xG per 90min", "Per 90 Minutes xAG": "xAG per 90min", "Per 90 Minutes xG+xAG": "xG + xAG per 90min", "Expected xG+xAG": "xG + xAG", "Performance GA": "Goals allowed [GK]", "Performance GA90": "Goals allowed per 90min [GK]", "Performance SoTA": "SoT faced [GK]", "Performance Saves": "Saves [GK]", "Performance Save%": "Saves % [GK]", "Performance CS%": "Clean sheets % [GK]", "Playing Time Mn/MP": "Minutes on pitch per match", "Playing Time Min%": "% of minutes on pitch", "Starts Starts": "How many time in 1st squad", "Starts Mn/Start": "Avg Minutes when used as starter", "Team Success onG": "Goals scored by team when on pitch", "Team Success onGA": "Goals lost by team when on pitch", "Team Success +/-90": "Goals scored vs lost by team when on pitch", "Team Success (xG) onxG": "xG scored by team when on pitch", "Team Success (xG) onxGA": "xG allowed scored by team when on pitch", "Team Success (xG) xG+/-90": "Expected goals scored vs lost by team when on pitch", "KP": "Passes led to shot", "PPA": "Passes into Penalty Box", "CrsPA": "Crosses into Penalty Box", "Touches Att 3rd": "Touches in last 3rd", "Carries CPA": "Carries into Penalty Box" }, inplace=True)
    df_final['Nation'] = df_final['Nation'].str.split(' ').str[1]
    df_final['Position'] = df_final['Position'].str.split(' ').str[0]
    df_final['Age'] = df_final['Age'].str.split('-').str[0]

    # saving dataset
    df_final.to_csv('players_fbref.csv', encoding='utf-8')

    pass



def fpl_player_stats():
    ### Downloading dataset
    od.download(
        "https://www.kaggle.com/datasets/meraxes10/fantasy-premier-league-2024",force=True)

    ### Cleaning data
    df_playersfpl = pd.read_csv('fantasy-premier-league-2024\players.csv')
    # get rid of unactive players (players on loan, suspended for long period)
    df_playersfpl = df_playersfpl[df_playersfpl['status'] != "u"]
    # data customization
    df_playersfpl['now_cost'] = df_playersfpl['now_cost']/10
    df_playersfpl['cost_change_start'] = df_playersfpl['cost_change_start']/10

    # selection of the data
    df_playersfpl = df_playersfpl[[
    "id",
    "name",
    "position",
    "team",
    "status",
    "now_cost",
    "total_points",
    "selected_by_percent",
    "news",
    "minutes",
    "starts",
    "points_per_game",
    "goals_scored",
    "expected_goals",
    "expected_goals_per_90",
    "expected_goal_involvements",
    "expected_goal_involvements_per_90",
    "goals_conceded",
    "goals_conceded_per_90",
    "expected_goals_conceded",
    "expected_goals_conceded_per_90",
    "assists",
    "expected_assists",
    "expected_assists_per_90",
    "yellow_cards",
    "saves",
    "saves_per_90",
    "clean_sheets",
    "clean_sheets_per_90",
    "bonus",
    "form",
    "threat",
    "creativity",
    "influence",
    "penalties_order",
    "direct_freekicks_order",
    "corners_and_indirect_freekicks_order"
    ]]


    ### Data Standardization
    # Due to this process it will be possible to compare the team data between two data sources
    teams_kaggle = ['Arsenal', 'Aston Villa', 'Bournemouth', 'Brentford', 'Brighton', 'Burnley',
    'Chelsea', 'Crystal Palace', 'Everton', 'Fulham', 'Liverpool', 'Luton',
    'Man City', 'Man Utd', 'Newcastle', "Nott'm Forest", 'Sheffield Utd', 'Spurs',
    'West Ham', 'Wolves']

    teams_fbref = ['Arsenal','Aston Villa','Bournemouth','Brentford','Brighton','Burnley',
    'Chelsea','Crystal Palace','Everton','Fulham','Liverpool','Luton Town',
    'Manchester City','Manchester Utd','Newcastle Utd','Nott\'ham Forest','Sheffield Utd','Tottenham','West Ham',
    'Wolves'
    ]

    df_playersfpl.replace(teams_kaggle,teams_fbref,inplace=True)


    # Exporting data for future purposes
    df_playersfpl.to_csv('fantasy-premier-league-2024\players.csv',encoding='utf-8') 

    pass


def prev_season_matches():
    ### Getting the data
    url_df = 'https://fbref.com/en/comps/9/schedule/Premier-League-Scores-and-Fixtures'
    df_schedule_22_23 = pd.read_html(url_df)[0]

    ### Data cleaning
    df_schedule_22_23[['Home Goals', 'Away Goals']] = df_schedule_22_23['Score'].str.split('–', expand=True, n=1)
    df_schedule_22_23 = df_schedule_22_23[[
    "Wk",
    "Date",
    "Home",
    "xG",
    'Home Goals', 
    'Away Goals',
    "xG.1",
    "Away"
    ]]
    df_schedule_22_23.rename(columns={"xG" : "xG Home","xG.1" : "xG Away"}, inplace=True)
    df_schedule_22_23['Season'] = '2022/2023'
    df_schedule_22_23['Home'].replace('', np.nan, inplace=True)
    df_schedule_22_23.dropna(subset=['Home'], inplace=True)
    df_schedule_22_23.to_csv('calendar_22_23.csv',encoding='utf-8') 


    pass

def current_season_matches():
    ### Getting the needed data
    url_df = 'https://fbref.com/en/comps/9/2024-2025/schedule/2024-2025-Premier-League-Scores-and-Fixtures'
    df_schedule_22_23 = pd.read_csv('calendar_22_23.csv')
    df_schedule_23_24 = pd.read_html(url_df)[0]

    ### Data cleaning
    df_schedule_23_24[['Home Goals', 'Away Goals']] = df_schedule_23_24['Score'].str.split('–', expand=True, n=1)
    df_schedule_23_24 = df_schedule_23_24[[
    "Wk",
    "Date",
    "Home",
    "xG",
    'Home Goals', 
    'Away Goals',
    "xG.1",
    "Away",
    "Notes"
    ]]
    df_schedule_23_24.rename(columns={"xG" : "xG Home","xG.1" : "xG Away"}, inplace=True)
    df_schedule_23_24['Season'] = '2023/2024'
    df_schedule_23_24['Home'].replace('', np.nan, inplace=True)
    df_schedule_23_24.dropna(subset=['Home'], inplace=True)

    ### Joining data
    df_seasons = [df_schedule_22_23,df_schedule_23_24]
    df_pl_calendar = pd.concat(df_seasons)
    df_pl_calendar.to_csv('Matches_and_results.csv',encoding='utf-8') 

    pass


### Call functions to actualize data
# 1st raw file
#fbref_player_stats()

# 2nd raw file
#fpl_player_stats()

# 3rd raw file - archive data, once exists doesn't need actualization
#file_path = 'calendar_22_23.csv'
#if not os.path.exists(file_path):
#    prev_season_matches()
#else:
#    pass

# 4th raw file
prev_season_matches()
current_season_matches()