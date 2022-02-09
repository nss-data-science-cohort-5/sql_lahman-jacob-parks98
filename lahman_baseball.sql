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
AND sb + cs > 20
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

SELECT name,w
FROM teams
WHERE w = 
(SELECT MIN(w)
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND wswin = 'Y')
AND wswin = 'Y';

/* The smallest number of wins for a world series winner was 63, done by the Dodgers */



SELECT MAX
FROM teams
WHERE yearid = 2016;
