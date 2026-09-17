# Netflix Global Catalog Analytics & Intelligence Dashboard

## Overview
This repository contains an end-to-end data analytics and business intelligence project examining Netflix's content library dynamics using a 2020 catalog dataset. The solution connects PostgreSQL data exploration with Power BI Desktop modeling to evaluate catalog composition, geographic distribution, underserved markets, movie runtime trajectories, acquisition freshness, and TV show renewal patterns.

## Dataset Specification
- Data Source: `public netflix_titles`
- Temporal Scope: Catalog releases and additions through 2020 (~8,800 records)
- Primary Attributes:
  - `show_id`: Unique record identifier
  - `type`: Content classification (`Movie` vs `TV Show`)
  - `title`: Program title
  - `director`: Film or show director(s)
  - `cast`: Listed cast members
  - `country`: Production and distribution territories
  - `date_added`: Platform addition date
  - `release_year`: Original production/release year
  - `rating`: Target demographic classification (`TV-MA`, `TV-14`, `R`, `PG`, etc.)
  - `duration`: Raw length string (`min` for movies, `Season`/`Seasons` for series)
  - `duration_min`: Parsed numeric duration for films
  - `duration_seasons`: Parsed numeric count of seasons for TV shows
  - `listed_in`: Associated content genres and categories
  - `description`: Catalog synopsis

## Key Questions Answered
1. Content Volume Dynamics: How has catalog production expanded across movies versus episodic series over historical release years?
2. International Production Hubs: Which countries constitute the core content pipeline for Netflix?
3. Underserved Catalog Blind Spots: Which territories possess low presence (5 or fewer indexed titles) requiring targeted acquisition?
4. Content Runtime Trajectory: How has the average duration of feature films evolved over release decades?
5. TV Show Retention & Shelf-Life: What proportion of episodic shows stop at Season 1 versus getting renewed or establishing multi-season franchise longevity?
6. Catalog Freshness: What is the distribution of acquisition lag (the latency in years between original release and inclusion on Netflix)?
7. Category Concentration: Which genres and content classifications drive the highest volume across the library?

## Technical Architecture

### 1. PostgreSQL Data Exploration & Segmentation

Content Volume by Type and Year:
```sql
SELECT 
    release_year,
    type,
    COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY release_year, type
ORDER BY release_year DESC;
```

High-Volume vs. Underserved Geographic Markets:
```sql
-- Top producing countries
SELECT 
    country,
    COUNT(*) AS total_titles
FROM netflix_titles
WHERE country IS NOT NULL AND country != 'Unknown'
GROUP BY country
ORDER BY total_titles DESC
LIMIT 10;

-- Low catalog presence / Underserved markets
SELECT 
    country,
    COUNT(*) AS total_titles
FROM netflix_titles
WHERE country IS NOT NULL AND country != 'Unknown'
GROUP BY country
HAVING COUNT(*) <= 5
ORDER BY total_titles ASC;
```

Show Lifespan & Renewal Rates:
```sql
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
```

Catalog Freshness (Acquisition Latency):
```sql
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
```

### 2. Power BI DAX Modeling & Calculated Columns

TV Show Lifespan Categorization:
```dax
show_lifespan = 
SWITCH(
    TRUE(),
    'public netflix_titles'[duration_seasons] = 1, "1 Season (Limited / Cancelled)",
    'public netflix_titles'[duration_seasons] = 2, "2 Seasons",
    'public netflix_titles'[duration_seasons] >= 3 && 'public netflix_titles'[duration_seasons] <= 5, "3 - 5 Seasons",
    'public netflix_titles'[duration_seasons] >= 6, "6+ Seasons (Long-Running Franchise)",
    BLANK()
)
```

Content Acquisition Gap (Years Latency):
```dax
years_gap = 
IF(
    NOT(ISBLANK('public netflix_titles'[date_added])) && 
    NOT(ISBLANK('public netflix_titles'[release_year])) &&
    YEAR('public netflix_titles'[date_added]) >= 'public netflix_titles'[release_year],
    YEAR('public netflix_titles'[date_added]) - 'public netflix_titles'[release_year],
    BLANK()
)
```

Movie Runtime Numeric Parsing:
```dax
duration_min = 
IF(
    'public netflix_titles'[type] = "Movie" && CONTAINSSTRING('public netflix_titles'[duration], "min"),
    VALUE(TRIM(SUBSTITUTE('public netflix_titles'[duration], "min", ""))),
    BLANK()
)
```

TV Show Season Count Extraction:
```dax
duration_seasons = 
IF(
    'public netflix_titles'[type] = "TV Show",
    VALUE(TRIM(SUBSTITUTE(SUBSTITUTE('public netflix_titles'[duration], "Seasons", ""), "Season", ""))),
    BLANK()
)
```

### 3. Dashboard Visuals & Layout
- Catalog Growth by Year: Line chart comparing Movie vs. TV Show volume trajectories.
- Top 10 Producing Countries: Horizontal clustered bar chart highlighting dominant markets.
- Underserved Markets: Scrollable filtered table identifying low-catalog regions (`<= 5` titles).
- Average Movie Runtime Over Time: Continuous trendline tracking movie length fluctuations across historical release years.
- TV Show Lifespan & Renewal Breakdown: Donut chart displaying season survival distributions.
- Top 10 Content Genres & Categories: Filtered Top-N clustered bar chart of driving catalog classifications.
- Catalog Freshness (Acquisition Gap): Clustered column distribution tracking immediate acquisitions versus archival releases.


