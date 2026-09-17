select * from netflix_titles

--is netflix primarily movies or series?
SELECT 
    type,
    COUNT(*) AS total_titles,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_share
FROM netflix_titles
GROUP BY type
ORDER BY total_titles DESC;

--how has the catalog changed over the years?
SELECT 
    EXTRACT(YEAR FROM date_added) AS year_added,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) AS movies_added,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) AS tv_shows_added,
    COUNT(*) AS total_added,
    ROUND(
        COUNT(CASE WHEN type = 'TV Show' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 
        2
    ) AS tv_show_percentage
FROM netflix_titles
WHERE date_added IS NOT NULL
GROUP BY year_added
ORDER BY year_added ASC;

--what are the top 10 content producing countried on netflix while fitering out records where country data was missing or unknown?
select
country,
count(*) as total_titles
from netflix_titles
where country is not null and country!= 'unknown'
group by country
order by total_titles DESC
limit 10;

--a major market might look well-presented in raw title counts but it could be almost
--entirely movies with no series releasing and visa versa leaving the subscriners in that region undeserved.
SELECT 
    country,
    COUNT(*) AS total_titles,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) AS movie_count,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) AS tv_show_count
FROM netflix_titles
WHERE country IS NOT NULL 
  AND country != 'Unknown'
GROUP BY country
HAVING COUNT(*) >= 50
ORDER BY tv_show_count ASC;

--to identify countries where netflix's content pipeline is nearly nonexistent despite having atleast some localized titles.
SELECT
country,
COUNT(*) AS total_titles
FROM netflix_titles
where country!= 'unknown'
group by country
having count(*)<=5
order by total_titles asc, country asc;

-- what age demographics dominate the library?
SELECT
CASE 
WHEN rating IN ('TV-MA', 'R', 'NC-17', 'UR', 'NR') THEN 'adult (18+)'
WHEN rating IN ('TV-14', 'PG-13') THEN 'teens (13-14)'
WHEN rating IN ('TV-PG', 'PG') THEN 'older kids/ parental guidance (7-12)'
WHEN rating IN ('TV-Y','TV-Y7','TV-Y7-FV','TV-G','G') THEN 'kids/all ages'
ELSE 'unrated/others'
END AS target_demographics,
COUNT(*) AS total_titles,
ROUND(COUNT(*)* 100.0/ SUM(COUNT(*)) OVER (),2) AS percentage_share
FROM netflix_titles
GROUP BY target_demographics
ORDER BY total_titles desc;

-- is this platform ready for family/kids expansion, or is it heavily skewed toward mature audiences?
SELECT 
    CASE 
        WHEN rating IN ('TV-MA', 'R', 'NC-17') THEN 'Mature (18+)'
        WHEN rating IN ('TV-14', 'PG-13') THEN 'Teens (13-17)'
        WHEN rating IN ('TV-PG', 'PG', 'TV-Y', 'TV-Y7', 'TV-G', 'G') THEN 'Kids & Family'
        ELSE 'Other / Unknown'
    END AS audience_category,
    COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY audience_category
ORDER BY total_titles DESC;

--Are movies getting longer or shorter over time?
SELECT
release_year,
AVG(duration_min) AS avg_duration
FROM netflix_titles
WHERE type= 'Movie'
GROUP BY release_year
ORDER BY release_year DESC;

--Do shows get renewed, or do most die after Season 1?
SELECT 
    CASE 
        WHEN duration_seasons = 1 THEN '1 Season (Limited / Cancelled)'
        WHEN duration_seasons = 2 THEN '2 Seasons'
        WHEN duration_seasons BETWEEN 3 AND 5 THEN '3 - 5 Seasons'
        ELSE '6+ Seasons (Long-Running Franchise)'
    END AS show_lifespan,
    COUNT(*) AS total_shows,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_tv_catalog
FROM netflix_titles
WHERE LOWER(TRIM(type)) = 'tv show'
  AND duration_seasons IS NOT NULL
GROUP BY show_lifespan
ORDER BY total_shows DESC;

--What Types of Stories Drive the Catalog?
SELECT 
    listed_in,
    COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY listed_in
ORDER BY total_titles DESC
LIMIT 10;

--How "Fresh" Is the Catalog?
SELECT 
    EXTRACT(YEAR FROM date_added) - release_year AS years_gap,
    COUNT(*) AS total_titles
FROM netflix_titles
WHERE date_added IS NOT NULL 
  AND release_year IS NOT NULL
  AND EXTRACT(YEAR FROM date_added) >= release_year
GROUP BY years_gap
ORDER BY years_gap ASC
LIMIT 10;
