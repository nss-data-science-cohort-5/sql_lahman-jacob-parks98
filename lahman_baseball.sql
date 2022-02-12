SELECT *
FROM allstarfull
LIMIT 5;

/* 1. Find all players in the database who played at Vanderbilt University. Create a list showing each player's 
first and last names as well as the total salary they earned in the major leagues. Sort this list in descending 
order by the total salary earned. Which Vanderbilt player earned the most money in the majors? */

SELECT namefirst || ' ' || namelast AS name, schoolname, SUM(salary) AS total_salary
FROM people
INNER JOIN collegeplaying AS cp
USING (playerid)
INNER JOIN schools
USING (schoolid)
INNER JOIN salaries
USING (playerid)
WHERE schoolname = 'Vanderbilt University'
GROUP BY name, schoolname
ORDER BY total_salary DESC;

--Josh CORRECT
SELECT 
	namefirst, 
	namelast, 
	SUM(salary)::numeric::money AS total_salary
FROM people
INNER JOIN salaries
	USING (playerid)
WHERE playerid IN
	(
	SELECT playerid
	FROM collegeplaying
	WHERE schoolid = 'vandy'
	)
GROUP BY namefirst, namelast
ORDER BY total_salary DESC;


--David Price, deservedly, has made the highest total salary

/* 2. Using the fielding table, group players into three groups based on their position: label players with 
position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position
"P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016. */
SELECT * 
FROM fielding
LIMIT 5;

SELECT 
	CASE WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
	ELSE 'Battery' END AS position_group,
	SUM(po) AS putouts
FROM fielding
WHERE yearid = 2016
GROUP BY position_group
ORDER BY putouts DESC ;

--In 2016 infielders had the most putouts, followed by pitchers and catchers, followed outfielders

/* 3. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 
decimal places. Do the same for home runs per game. Do you see any trends? */

WITH decades AS (
SELECT 
	generate_series(1920, 2010, 10) AS lower,
	generate_series(1929, 2020, 10) AS upper
)

SELECT 
	lower,
	upper,
	ROUND(SUM(so) * 1.0/SUM(g), 2) AS so_per_game,
	ROUND(SUM(hr)*1.0/SUM(g), 2) AS hr_per_game
FROM decades
LEFT JOIN teams
	ON yearid >= lower
	AND yearid <= upper
GROUP BY lower,upper
ORDER BY lower;
	
-- Both strikeouts and home runs per game have been increasing steadily since 1920

/* 4. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the 
percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen 
base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases. Report the 
players' names, number of stolen bases, number of attempts, and stolen base percentage. */

SELECT 
	namefirst || ' ' || namelast AS playername,
	sb,
	cs,
	ROUND(sb*100.0/(cs + sb),2) AS success_percentage
FROM batting
INNER JOIN people
USING (playerid)
WHERE yearid = 2016
AND sb + cs >= 20
ORDER BY success_percentage DESC;

--Michael
WITH full_batting AS (
	SELECT 
		playerid,
		SUM(sb) AS sb,
		SUM(cs) AS cs,
		SUM(sb) + SUM(cs) AS attempts
	FROM batting
	WHERE yearid = 2016
	GROUP BY playerid
)
SELECT 
	namefirst || ' ' || namelast AS name,
	sb,
	attempts,
	ROUND(sb * 100.0 / attempts, 2) AS sb_percentage
FROM full_batting
INNER JOIN people
USING (playerid)
WHERE attempts >= 20
ORDER BY sb_percentage DESC;

	
/* Chris Owings had the most success stealing bases, but in my humble opinion, Billy Hamilton was far 
more impressive on the basepaths */

/* 5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? 
What is the smallest number of wins for a team that did win the world series? Doing this will probably result 
in an unusually small number of wins for a world series champion; determine why this is the case. Then redo your
query, excluding the problem year. How often from 1970 to 2016 was it the case that a team with the most wins 
also won the world series? What percentage of the time? */

SELECT name,w
FROM teams
WHERE w = 
(SELECT MAX(w)
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND wswin = 'N')
AND wswin = 'N';

/* The largest number of wins by a team that did not win it all was 116, done twice, once by the cubs and once 
by the mariners */

SELECT name,w, yearid
FROM teams
WHERE w = 
(SELECT MIN(w)
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND wswin = 'Y')
AND wswin = 'Y';

/* The smallest number of wins for a world series winner was 63, done by the Dodgers in the 1981 season
in which there was a players strike, much like this season. */

SELECT name,w, yearid
FROM teams
WHERE w = 
(SELECT MIN(w)
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
 AND yearid != 1981
AND wswin = 'Y')
AND wswin = 'Y';

--excluding 1981, the minimum number of games won by a world series winner was 83.

WITH wins AS (
	SELECT yearid, w
	FROM teams 
	WHERE wswin = 'Y'
	AND yearid BETWEEN 1970 AND 2016
),
max_wins AS (
	SELECT yearid, MAX(w) AS max_w
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
	GROUP BY yearid
)
SELECT 
	(SELECT COUNT(*)
	FROM wins
	INNER JOIN max_wins
	USING (yearid)
	WHERE w = max_w) AS years, 
	(SELECT COUNT(*)
	FROM wins
	INNER JOIN max_wins
	USING (yearid)
	WHERE w = max_w) *100.0 / (SELECT COUNT(*)
	FROM wins) AS percentage


/* There were 12 years where the team that won the most regular season also won the world series from 1970 to 2016. This was
26% of the time. */

--Michael's Approach:
WITH max_wins AS (
	SELECT 
		yearid,
		MAX(w) AS max_wins
	FROM teams
	WHERE yearid >= 1970
	GROUP BY yearid
	ORDER BY yearid
),
team_with_most_wins AS (
	SELECT m.yearid, max_wins, name, wswin
	FROM max_wins m
	INNER JOIN teams t
	ON max_wins = w AND m.yearid = t.yearid
)
SELECT
ROUND(
(SELECT COUNT(*)
FROM team_with_most_wins
WHERE wswin = 'Y') * 100.0 / (SELECT COUNT(*) FROM team_with_most_wins), 2) AS ws_win_pct;


/* 6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American 
League (AL)? Give their full name and the teams that they were managing when they won the award. */
--COME BACK

WITH two_league_winners AS (
	SELECT 
		namefirst || ' ' || namelast AS name,
		COUNT(DISTINCT lgid) AS al_nL_count
	FROM awardsmanagers
	INNER JOIN people
	USING (playerid)
	WHERE awardid = 'TSN Manager of the Year'
	AND lgid IN ('AL', 'NL')
	GROUP BY name
	HAVING COUNT(DISTINCT lgid) >= 2)
SELECT DISTINCT 
	namefirst || ' ' || namelast AS name,
	t.name AS team_name,
	am.lgid, 
	am.yearid
FROM awardsmanagers AS am
INNER JOIN people
USING (playerid)
INNER JOIN managers
USING (playerid,yearid)
INNER JOIN teams AS t
USING(teamid, yearid)
WHERE awardid = 'TSN Manager of the Year'
AND namefirst || ' ' || namelast IN (SELECT name FROM two_league_winners)
ORDER BY name;



/*7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at
least 10 games (across all teams). Note that pitchers often play for more than one team in a season,
so be sure that you are counting all stats for each player. */

SELECT namefirst || ' ' || namelast AS name, MAX(salary) / SUM(so) AS salary_per_SO
FROM pitching as p1
INNER JOIN people AS p2
USING (playerid)
INNER JOIN salaries
USING (playerid, yearid)
WHERE p1.yearid = 2016
GROUP BY name
HAVING SUM(gs) >= 10
ORDER BY salary_per_SO DESC;

--Chris
WITH strikeouts AS (
	SELECT 
		playerid, 
		SUM(so) AS year_strikeouts
	FROM pitching
	WHERE yearid = 2016
	GROUP BY playerid
	HAVING SUM(gs) >= 10
)

SELECT
	namefirst,
	namelast,
	TO_CHAR(ROUND(salary::numeric/year_strikeouts,2),'l999,999,999D99') AS efficiency
FROM strikeouts
INNER JOIN people
USING (playerid)
INNER JOIN salaries
USING (playerid)
WHERE salaries.yearid = 2016
ORDER BY efficiency DESC;


--Robbie Ray was the most efficient pitcher in salary per strikeout in 2016

/* 8. Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the 
year they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.)
Note that a player being inducted into the hall of fame is indicated by a 'Y' in the **inducted** column of the halloffame
table. */

WITH threek_hits AS (SELECT 
	namefirst || ' ' || namelast AS name, 
	playerid,
	SUM(h)
FROM batting
INNER JOIN people
USING(playerid)
GROUP BY name,playerid
HAVING SUM(h) >=3000
ORDER BY name),
unique_hof_y AS (
SELECT DISTINCT playerid, inducted, MAX(yearid) AS yearid
FROM halloffame
WHERE inducted = 'Y'
GROUP BY playerid, inducted
)

SELECT name,
yearid
FROM threek_hits
LEFT JOIN unique_hof_y
USING (playerid);

--Chris
WITH career_hits AS (
	SELECT
		playerid,
		SUM(h) AS career_hits
	FROM batting
	GROUP BY playerid
	HAVING SUM(h) >= 3000
)

SELECT
	DISTINCT namefirst || ' ' || namelast AS name,
	career_hits,
	CASE WHEN inducted = 'Y' THEN hof.yearid
	ELSE NULL
	END AS hall_of_fame_induction
FROM career_hits
INNER JOIN people
USING (playerid)
INNER JOIN halloffame AS hof
USING (playerid)
ORDER BY name;

--Josh
WITH hof AS (
	SELECT *
	FROM halloffame
	WHERE inducted = 'Y'
)
SELECT
	namefirst,
	namelast,
	SUM(h),
	hof.yearid
FROM batting
INNER JOIN people
	USING (playerid)
LEFT JOIN hof
	USING (playerid)
GROUP BY playerid, namefirst, namelast, hof.yearid
HAVING sum(h) >= 3000
ORDER BY namefirst;

SELECT 
	namefirst || ' ' || namelast AS name, 
	SUM(h)
FROM batting
INNER JOIN people
USING(playerid)
GROUP BY name
HAVING SUM(h) >=3000
ORDER BY name




/* 9. Find all players who had at least 1,000 hits for two different teams.
Report those players' full names. */
WITH onek_hits AS (
	SELECT 
		namefirst || ' ' || namelast AS player,
		playerid,
		teams.name AS team,
		SUM(batting.h)
	FROM batting
	INNER JOIN people
	USING (playerid)
	INNER JOIN teams
	USING (teamid,yearid)
	GROUP BY player,playerid, team
	HAVING SUM(batting.h) > 1000
	ORDER BY player),
two_teams AS 
	(SELECT 
		player,
		COUNT(player)
	FROM onek_hits
	GROUP BY player
	HAVING COUNT(player) >=2)
SELECT *
FROM onek_hits
INNER JOIN two_teams
USING(player);

/* 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played 
in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names 
and the number of home runs they hit in 2016. */

WITH max_hr AS (
SELECT 
	namefirst || ' ' || namelast AS player,
	MAX(hr) AS career_high
FROM batting
INNER JOIN people
USING(playerid)
GROUP BY player
ORDER BY MAX(hr) DESC
),
ten_years_played AS (
SELECT 
	namefirst || ' ' || namelast AS player,
	COUNT(DISTINCT yearid) AS seasons
FROM batting
INNER JOIN people
USING(playerid)
GROUP BY player
	HAVING COUNT(DISTINCT yearid) > 10	
),
HR_2016 AS (
SELECT 
	namefirst || ' ' || namelast AS player,
	SUM(hr) AS hr_2016
FROM batting
INNER JOIN people
USING(playerid)
WHERE yearid = 2016
GROUP BY player
)
SELECT *
FROM HR_2016
INNER JOIN ten_years_played
USING(player)
INNER JOIN max_hr
USING(player)
WHERE career_high = hr_2016
AND hr_2016 > 0
	
--10 players hit their career high in home runs in 2016

--WINDOW FUNCTIONS
--1
/* Write a query which retrieves each teamid and number of wins (w) for the 2016 season. Apply three window functions to 
the number of wins (ordered in descending order) - ROW_NUMBER, RANK, AND DENSE_RANK. 
Compare the output from these three functions. What do you notice? */

SELECT 
	teamid,
	w,
	RANK() OVER(ORDER BY w DESC) AS rank,
	ROW_NUMBER() OVER(ORDER BY w DESC) AS row_number,
	DENSE_RANK() OVER(ORDER BY w DESC) AS dense_rank
FROM teams
WHERE yearid = 2016

--The rank and dense rank functions account for ties, the row number does not. The Dense rank counts ties as one rank.

--1b
/* Which team has finished in last place in its division (i.e. with the least number of wins) the most number of times? 
A team's division is indicated by the divid column in the teams table. */

WITH div_loss AS (
	SELECT 
		name,
		yearid,
		lgid,
		RANK() OVER(PARTITION BY yearid,divid,lgid
				   ORDER BY l DESC) AS rank
	FROM teams
	WHERE divid IS NOT NULL)
SELECT name, COUNT(name) AS division_losses
FROM div_loss
WHERE rank = 1
GROUP BY name
ORDER BY division_losses DESC;

--2a
/*
Barry Bonds has the record for the highest career home runs, with 762. Write a query which returns, for each season of 
Bonds' career the total number of seasons he had played and his total career home runs at the end of that season. 
(Barry Bonds' playerid is bondsba01.) */

SELECT 
	namefirst || ' ' || namelast AS player,
	yearid,
	hr,
	SUM(hr) OVER(ORDER BY yearid ROWS BETWEEN unbounded preceding AND CURRENT ROW) AS career_hr,
	COUNT(yearid) OVER(ORDER BY yearid ROWS BETWEEN unbounded preceding AND CURRENT ROW) AS seasons
FROM batting
INNER JOIN people
USING (playerid)
WHERE playerid = 'bondsba01'

--2b
/* 

How many players at the end of the 2016 season were on pace to beat Barry Bonds' record? 
For this question, we will consider a player to be on pace to beat Bonds' record if they have more home runs than Barry 
Bonds had the same number of seasons into his career. */


WITH bonds AS (
	SELECT 
		namefirst || ' ' || namelast AS player,
		yearid,
		hr,
		SUM(hr) OVER(ORDER BY yearid ROWS BETWEEN unbounded preceding AND CURRENT ROW) AS career_hr_bonds,
		COUNT(yearid) OVER(ORDER BY yearid ROWS BETWEEN unbounded preceding AND CURRENT ROW) AS seasons_bonds
	FROM batting
	INNER JOIN people
	USING (playerid)
	WHERE playerid = 'bondsba01'
),

other_players AS (
SELECT 
	namefirst || ' ' || namelast AS player,
	yearid,
	SUM(hr) OVER(PARTITION BY playerid ORDER BY yearid ROWS BETWEEN unbounded preceding AND CURRENT ROW) AS career_hr_player,
	COUNT(yearid) OVER(PARTITION BY playerid ORDER BY yearid ROWS BETWEEN unbounded preceding AND CURRENT ROW) AS seasons_player
FROM batting
INNER JOIN people
USING (playerid)
WHERE yearid = 2016)

SELECT COUNT(DISTINCT player), AVG(seasons_player)
FROM (
	SELECT op.player, career_hr_player, career_hr_bonds, seasons_player, seasons_bonds
	FROM other_players AS op
	INNER JOIN bonds AS B
	ON op.seasons_player = b.seasons_bonds
	WHERE career_hr_player > career_hr_bonds
) AS comparison

--122 players are on pace to break barry bonds' record, however, zero players who have played 5 seasons are on pace.
/* All of the players on pace to beat barry bonds' record only had played 1 season by 2016. This means they only had to hit
one HR. */

--2c
/*
Were there any players who 20 years into their career who had hit more home runs at that point into their
career than Barry Bonds had hit 20 years into his career? */

WITH bonds AS (
	SELECT 
		namefirst || ' ' || namelast AS player,
		yearid,
		hr,
		SUM(hr) OVER(ORDER BY yearid ROWS BETWEEN unbounded preceding AND CURRENT ROW) AS career_hr_bonds,
		COUNT(yearid) OVER(ORDER BY yearid ROWS BETWEEN unbounded preceding AND CURRENT ROW) AS seasons_bonds
	FROM batting
	INNER JOIN people
	USING (playerid)
	WHERE playerid = 'bondsba01'
),

other_players AS (
SELECT 
	namefirst || ' ' || namelast AS player,
	yearid,
	SUM(hr) OVER(PARTITION BY playerid ORDER BY yearid ROWS BETWEEN unbounded preceding AND CURRENT ROW) AS career_hr_player,
	COUNT(yearid) OVER(PARTITION BY playerid ORDER BY yearid ROWS BETWEEN unbounded preceding AND CURRENT ROW) AS seasons_player
FROM batting
INNER JOIN people
USING (playerid))

SELECT op.player, career_hr_player, career_hr_bonds, seasons_player, seasons_bonds
	FROM other_players AS op
	INNER JOIN bonds AS B
	ON op.seasons_player = b.seasons_bonds
	WHERE career_hr_player > career_hr_bonds
	AND seasons_bonds = 20
	
-- Only Hammerin' Hank, who is the true home run king, had more homers through 20 season than Barry Bonds

--3
/* Find the player who had the most anomalous season in terms of number of home runs hit. To do this, find the player who 
has the largest gap between the number of home runs hit in a season and the 5-year moving average number of home runs if we
consider the 5-year window centered at that year (the window should include that year, the two years prior and the two years
after). */
WITH rolling_avg AS (
	SELECT
		namefirst || ' ' || namelast AS player,
		playerid,
		yearid,
		hr,
		AVG(hr) OVER(PARTITION BY playerid ORDER BY yearid ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS rolling_avg
	FROM batting
	INNER JOIN people 
	USING (playerid))
SELECT 
	player,
	playerid,
	hr,
	rolling_avg,
	yearid,
	ABS(hr - rolling_avg) AS diff
FROM rolling_avg
ORDER BY diff DESC
LIMIT 5;

--Hank Greenberg had the most anomalous season in 1936. This is because he only played 12 games in 1936.

SELECT *
FROM batting
WHERE playerid = 'greenha01'

--4a
/* Warmup: How many players played at least 10 years in the league and played for exactly one team? 
(For this question, exclude any players who played in the 2016 season).
Who had the longest career with a single team? (You can probably answer this question without needing to use a 
window function.) */

SELECT namefirst || ' ' || namelast AS name, COUNT(DISTINCT yearid) AS seasons, COUNT(DISTINCT teamid) AS teams
FROM batting
INNER JOIN people
USING(playerid)
WHERE yearid < 2016
GROUP BY name
HAVING COUNT(DISTINCT yearid) >= 10 AND COUNT(DISTINCT teamid) = 1
ORDER BY seasons DESC;


--Brooks Robinson had the longest career with a single team. 166 players played at least 10 years with a single team.

--4b
/* Some players start and end their careers with the same team but play for other teams in between. For example, 
Barry Zito started his career with the Oakland Athletics, moved to the San Francisco Giants for 7 seasons before
returning to the Oakland Athletics for his final season. How many players played at least 10 years in the league and
start and end their careers with the same team but played for at least one other team during their career? For this 
question, exclude any players who played in the 2016 season. */

--work in progress
WITH players AS (
SELECT 
	namefirst || ' ' || namelast AS name,
	COUNT(DISTINCT yearid) AS seasons,
	COUNT(DISTINCT teamid) AS teams,
	MIN(yearid),
	MAX(yearid)
FROM batting
INNER JOIN people
USING(playerid)
WHERE yearid < 2016
GROUP BY name
HAVING COUNT(DISTINCT yearid) >= 10 AND COUNT(DISTINCT teamid) > 1
ORDER BY seasons DESC)

SELECT 






