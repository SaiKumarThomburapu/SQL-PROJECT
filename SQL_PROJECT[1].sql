/* Importing Tables */

create table stadiums (
Name varchar,
City varchar,
Country varchar,
capacity int
)
COPY stadiums FROM 'F:/SQL Project Files/Stadiums.csv' DELIMITER ',' CSV HEADER;
select * from stadiums

create table goals (
GOAL_ID varchar,
MATCH_ID varchar,
PID varchar,
DURATION int,
ASSIST varchar,
GOAL_DESC varchar
)
COPY goals FROM 'F:/SQL Project Files/goals.csv' DELIMITER ',' CSV HEADER;
select * from goals	

create table matches (
MATCH_ID varchar,
SEASON varchar,
DATE varchar,
HOME_TEAM varchar,
AWAY_TEAM varchar,
STADIUM varchar,
HOME_TEAM_SCORE int,
AWAY_TEAM_SCORE int,
PENALTY_SHOOT_OUT int,
ATTENDANCE int
)
COPY matches FROM 'F:/SQL Project Files/matches.csv' DELIMITER ',' CSV HEADER;
select * from matches	

create table players (
PLAYER_ID varchar,
FIRST_NAME varchar,
LAST_NAME varchar,
NATIONALITY varchar,
DOB varchar,
TEAM varchar,
JERSEY_NUMBER int,
POSITION varchar,
HEIGHT int,
WEIGHT int,
FOOT varchar)
COPY players FROM 'F:/SQL Project Files/Players.csv' DELIMITER ',' CSV HEADER;
select * from players	
					
create table teams (
TEAM_NAME varchar,
COUNTRY varchar,
HOME_STADIUM varchar
)
COPY teams FROM 'F:/SQL Project Files/Teams.csv' DELIMITER ',' CSV HEADER;
select * from teams	

/* Finally All files are dumped */
select * from players
select * from teams
select * from stadiums
select * from matches
select * from goals

/* 1)counting the total number of teams */
select * from teams
select count(distinct team_name) as number_of_teams from teams

/* 2)Find the Number of Teams per Country */
select country,count(team_name) as teams_per_country
from teams group by country order by country 

/* 3)Calculate the Average Team Name Length */
select avg(length(team_name)) as Avg_team_name_length from teams

/* 4)Calculate the Average Stadium Capacity in Each Country round it off and
sort by the total stadiums in the country. */
select * from stadiums
select country,count(name) as total_stadiums_country, round(avg(capacity)) as avg_stadium_capacity
from stadiums group by country order by total_stadiums_country

/* 5)Calculate the Total Goals Scored. */
select * from goals
select count(distinct goal_id) as Total_goals_scored from goals

/* 6)Find the total teams that have city in their names*/
select * from teams
select count(team_name) as teams_with_city from teams where team_name like '%City'

/* 7) Use Text Functions to Concatenate the Team's Name and Country */
select * from teams
select (team_name ||', '|| country) as Concatenation_name from teams

/* 8) What is the highest attendance recorded in the dataset, 
and which match (including home and away teams, and date) does it correspond to? */
select * from matches
select home_team,away_team,date,attendance from matches 
where attendance=(select max(attendance) from matches)

/* 9)What is the lowest attendance recorded in the dataset, 
and which match (including home and away teams, and date)
does it correspond to set the criteria as greater than 1 as
some matches had 0 attendance because of covid. */
select * from matches
select home_team,away_team,date,attendance from matches 
where attendance=(select min(attendance) from matches where attendance>1)

/* 10)  Identify the match with the highest total score (sum of home and away team scores) 
in the dataset. Include the match ID, home and away teams, and the total score. */
select * from matches
select match_id,home_team,away_team,(home_team_score+away_team_score) as total_scores
from matches
where (home_team_score+away_team_score)=(select max((home_team_score+away_team_score))
from matches)

/* 11)Find the total goals scored by each team, distinguishing between home and away goals. 
Use a CASE WHEN statement to differentiate home and away goals within the subquery */
select * from matches
select teams,sum(home_team_goals) as home_goals,sum(away_team_goals)as away_goals
from (select 
home_team as teams,sum(home_team_score) as home_team_goals,0 as away_team_goals from matches
group by home_team
union all
select away_team as teams,0 as home_team_goals,sum(away_team_score) as away_team_goals from 
matches group by away_team) as team_goals
group by teams
order by home_goals desc,away_goals desc


/* 12)windows function - Rank teams based on their total scored goals (home and away combined)
using a window function.In the stadium Old Trafford. */
select * from matches
select teams,sum(home_goals+away_goals) as total_goals
from (select home_team as teams,sum(home_team_score) as home_goals,0 as away_goals
from matches group by home_team
union all
select away_team as teams,sum(away_team_score) as away_goals,0 as home_goals
from matches 
where stadium = 'Old Trafford' group by away_team) as goals
group by teams order by total_goals desc

create table tot_goals as (select teams,sum(home_goals+away_goals) as total_goals
from (select home_team as teams,sum(home_team_score) as home_goals,0 as away_goals
from matches where stadium = 'Old Trafford' group by home_team
union all
select away_team as teams,sum(away_team_score) as away_goals,0 as home_goals
from matches 
where stadium = 'Old Trafford' group by away_team) as goals
group by teams order by total_goals desc) 

select * from tot_goals
/* Result */
select teams,total_goals,dense_rank() over(order by total_goals desc) as teams_ranking
from tot_goals 

/* 13) TOP 5 l players who scored the most goals in Old Trafford, ensuring null values
are not included in the result (especially pertinent for cases where a player might not
have scored any goals). */
select * from players
select * from goals 
select * from matches

select p.player_id,p.first_name,p.last_name,
       g.number_of_goals,s.stadium from players as p
	   left join (select pid, count(goal_id) as number_of_goals,match_id from goals group by pid,match_id) as g
	   on p.player_id=g.pid
	   left join matches as s
	   on s.match_id=g.match_id
	   where s.stadium = 'Old Trafford' and g.number_of_goals is not null
	   group by p.player_id,p.first_name,p.last_name,g.number_of_goals,s.stadium
	   order by g.number_of_goals desc limit 5


/* 14)Write a query to list all players along with the total number of goals they have scored.
Order the results by the number of goals scored in descending order to easily identify the
top 6 scorers. */
select * from players
select * from goals

select p.player_id,p.first_name,p.last_name,
        g.number_of_goals from players as p
		inner join (select pid, count(goal_id) as number_of_goals from goals  group by pid) as g
	   on p.player_id=g.pid
	   group by p.player_id,p.first_name,p.last_name,g.number_of_goals
	   order by number_of_goals desc limit 6
		

/* 15)Identify the Top Scorer for Each Team - Find the player from each team who has
scored the most goals in all matches combined. This question requires joining the Players,
Goals, and possibly the Matches tables, and then using a subquery to aggregate goals by players
and teams. */
select * from players
select * from goals
select * from matches
select p.player_id,p.first_name,p.last_name,p.team,g.total_goals from players as p
inner join (select pid, count(goal_id) as total_goals  from goals group by pid)as g on p.player_id = g.pid
inner join (select p.team, max(g.total_goals) as max_goals from players as p
inner join (select pid, count(goal_id) as total_goals from goals group by pid)
as g on p.player_id = g.pid group by p.team)
as t on p.team = t.team and g.total_goals = t.max_goals;


/* 16) Find the Total Number of Goals Scored in the Latest Season -
Calculate the total number of goals scored in the latest season available in the dataset.
This question involves using a subquery to first identify the latest season from the Matches
table, then summing the goals from the Goals table that occurred in matches from that season. */
select * from matches
select sum(home_team_score+away_team_score) as total_number_of_goals,season
from matches
where season=(select max(season) from matches) group by season

/* 17) Find Matches with Above Average Attendance - Retrieve a list of matches
that had an attendance higher than the average attendance across all matches. 
This question requires a subquery to calculate the average attendance first, then
use it to filter matches. */
select * from matches
select match_id,season,home_team,away_team,stadium,attendance
from matches
where attendance>(select avg(attendance) from matches)
 
/*18)Find the Number of Matches Played Each Month - Count how many matches were played 
in each month across all seasons.This question requires extracting the month from the
match dates and grouping the results by this value. as January Feb march */
select * from matches
select  count(match_id) as number_of_matches,
to_char(to_date(date, 'DD-MM-YYYY'), 'FMMonth') as months from matches
group by months order by number_of_matches desc
 






