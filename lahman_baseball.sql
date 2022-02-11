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

--Josh
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
ORDER BY salary_per_SO;

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
	SUM(h)
FROM batting
INNER JOIN people
USING(playerid)
GROUP BY name
HAVING SUM(h) >=3000
ORDER BY name),
unique_hof_y AS (
SELECT DISTINCT playerid, inducted, yearid
FROM halloffame
WHERE inducted = 'Y'
)

SELECT namefirst || ' ' || namelast AS name, 
yearid
FROM people
LEFT JOIN unique_hof_y
USING (playerid)
WHERE namefirst || ' ' || namelast IN (SELECT name FROM threek_hits)

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




/* 9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names. */
