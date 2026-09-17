# Netflix Global Catalog Analytics & Intelligence Dashboard

## Overview
This repository contains an end-to-end data analytics and business intelligence project examining Netflix's catalog dynamics using a 2020 dataset. The project integrates SQL-based catalog exploration, custom DAX data modeling, and an executive-ready Power BI dashboard to assess content production volume, geographic distribution, runtime trends, catalog freshness, and TV show retention.

## Dataset Information
- Source Table: `public netflix_titles`
- Dataset Scope: Metadata through 2020 (8,800+ titles)
- Core Attributes: `show_id`, `type`, `title`, `director`, `cast`, `country`, `date_added`, `release_year`, `rating`, `duration`, `duration_min`, `duration_seasons`, `listed_in`, `description`

## Key Questions Answered
1. Content Mix Trajectory: How has the split between feature films and multi-episode TV shows evolved over decades?
2. Geographic Focus & Underserved Territories: Which countries dominate Netflix's output, and where are the primary catalog coverage gaps (countries with 5 or fewer titles)?
3. Content Duration Dynamics: How have average movie runtimes shifted historically across release years?
4. Series Longevity & Attrition: What percentage of TV shows survive past Season 1 versus reaching franchise longevity (3-5 or 6+ seasons)?
5. Acquisition Latency (Freshness): What is the typical gap between a title's original release year and its arrival on the Netflix platform?
6. Category Concentration: Which genres and content classifications drive the highest volume across the library?

## Technical Architecture

### 1. Data Transformation & SQL Analysis
SQL queries were designed to handle:
- Catalog volume breakdown by content type across release years.
- Top producing nations and identification of low-volume territories (`HAVING COUNT(*) <= 5`).
- Categorization of content lifespans via multi-condition `CASE` expressions.
- Acquisition latency calculation (`EXTRACT(YEAR FROM date_added) - release_year`).

### 2. Power BI DAX Modeling
To support downstream visual filtering and segmentation, calculated columns and expressions were created:

- **TV Show Lifespan Classification (`show_lifespan`)**:
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
