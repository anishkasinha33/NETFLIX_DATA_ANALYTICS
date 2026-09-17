# Netflix Global Catalog Analytics & Intelligence Dashboard[cite: 1, 2]

## Overview[cite: 1, 2]
This repository contains an end-to-end data analytics and business intelligence project examining Netflix's content library dynamics using a 2020 catalog dataset[cite: 1, 2]. The solution connects PostgreSQL data exploration with Power BI Desktop modeling to evaluate catalog composition, geographic distribution, underserved markets, movie runtime trajectories, acquisition freshness, and TV show renewal patterns[cite: 1, 2].

## Dataset Specification[cite: 1, 2]
- Data Source: `public netflix_titles`[cite: 1, 2]
- Temporal Scope: Catalog releases and additions through 2020 (~8,800 records)[cite: 1, 2]
- Primary Attributes:[cite: 1, 2]
  - `show_id`: Unique record identifier[cite: 1, 2]
  - `type`: Content classification (`Movie` vs `TV Show`)[cite: 1, 2]
  - `title`: Program title[cite: 1, 2]
  - `director`: Film or show director(s)[cite: 1, 2]
  - `cast`: Listed cast members[cite: 1, 2]
  - `country`: Production and distribution territories[cite: 1, 2]
  - `date_added`: Platform addition date[cite: 1, 2]
  - `release_year`: Original production/release year[cite: 1, 2]
  - `rating`: Target demographic classification (`TV-MA`, `TV-14`, `R`, `PG`, etc.)[cite: 1, 2]
  - `duration`: Raw length string (`min` for movies, `Season`/`Seasons` for series)[cite: 1, 2]
  - `duration_min`: Parsed numeric duration for films[cite: 1, 2]
  - `duration_seasons`: Parsed numeric count of seasons for TV shows[cite: 1, 2]
  - `listed_in`: Associated content genres and categories[cite: 1, 2]
  - `description`: Catalog synopsis[cite: 1, 2]

## Key Questions Answered[cite: 1, 2]
1. Content Mix Trajectory: How has the split between feature films and multi-episode TV shows evolved over decades?[cite: 1, 2]
2. Geographic Focus & Underserved Territories: Which countries dominate Netflix's output, and where are the primary catalog coverage gaps (countries with 5 or fewer titles)?[cite: 1, 2]
3. Content Duration Dynamics: How have average movie runtimes shifted historically across release years?[cite: 1, 2]
4. Series Longevity & Attrition: What percentage of TV shows survive past Season 1 versus reaching franchise longevity (3-5 or 6+ seasons)?[cite: 1, 2]
5. Acquisition Latency (Freshness): What is the typical gap between a title's original release year and its arrival on the Netflix platform?[cite: 1, 2]
6. Category Concentration: Which genres and content classifications drive the highest volume across the library?[cite: 1, 2]

## Technical Architecture[cite: 1, 2]

### 1. PostgreSQL Data Exploration & Segmentation[cite: 1, 2]

Content Volume by Type and Year:[cite: 1, 2]
```sql
SELECT 
    release_year,
    type,
    COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY release_year, type
ORDER BY release_year DESC;
```

High-Volume vs. Underserved Geographic Markets:[cite: 1, 2]
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

Show Lifespan & Renewal Rates:[cite: 1, 2]
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

Catalog Freshness (Acquisition Latency):[cite: 1, 2]
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

### 2. Power BI DAX Modeling & Calculated Columns[cite: 1, 2]

TV Show Lifespan Categorization:[cite: 1, 2]
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

Content Acquisition Gap (Years Latency):[cite: 1, 2]
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

Movie Runtime Numeric Parsing:[cite: 1, 2]
```dax
duration_min = 
IF(
    'public netflix_titles'[type] = "Movie" && CONTAINSSTRING('public netflix_titles'[duration], "min"),
    VALUE(TRIM(SUBSTITUTE('public netflix_titles'[duration], "min", ""))),
    BLANK()
)
```

TV Show Season Count Extraction:[cite: 1, 2]
```dax
duration_seasons = 
IF(
    'public netflix_titles'[type] = "TV Show",
    VALUE(TRIM(SUBSTITUTE(SUBSTITUTE('public netflix_titles'[duration], "Seasons", ""), "Season", ""))),
    BLANK()
)
```

### 3. Dashboard Visuals & Layout[cite: 1, 2]
- Catalog Growth by Year: Line chart comparing Movie vs. TV Show volume trajectories[cite: 1, 2].
- Top 10 Producing Countries: Horizontal clustered bar chart highlighting dominant markets[cite: 1, 2].
- Underserved Markets: Scrollable filtered table identifying low-catalog regions (`<= 5` titles)[cite: 1, 2].
- Average Movie Runtime Over Time: Continuous trendline tracking movie length fluctuations across historical release years[cite: 1, 2].
- TV Show Lifespan & Renewal Breakdown: Donut chart displaying season survival distributions[cite: 1, 2].
- Top 10 Content Genres & Categories: Filtered Top-N clustered bar chart of driving catalog classifications[cite: 1, 2].
- Catalog Freshness (Acquisition Gap): Clustered column distribution tracking immediate acquisitions versus archival releases[cite: 1, 2].

## Repository Structure[cite: 1, 2]
```
.
|-- README.md
|-- data/
|   `-- netflix_titles.csv
|-- sql/
|   `-- catalog_analysis_queries.sql
`-- pbix/
    `-- Netflix_Analysis_Dashboard.pbix
```

## How to Reproduce[cite: 1, 2]
1. Clone the repository:[cite: 1, 2]
   ```bash
   git clone [https://github.com/](https://github.com/)<your-username>/netflix-catalog-dashboard.git
   ```
2. Open Microsoft Power BI Desktop[cite: 1, 2].
3. Open `pbix/Netflix_Analysis_Dashboard.pbix`[cite: 1, 2].
4. Re-point data source if necessary via **Transform Data > Data Source Settings** to your local dataset[cite: 1, 2].
5. Click **Close & Apply** to refresh the dataset[cite: 1, 2].
