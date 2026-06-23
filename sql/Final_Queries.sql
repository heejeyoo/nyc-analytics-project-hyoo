-- Q1: Compares ACE violations and 311 illegal-parking complaints by borough.
-- This supports the Squeeze Index idea by showing where both enforcement activity
-- and public complaints are concentrated.

SELECT
    borough,
    series,
    SUM(event_count) AS event_count
FROM (
    SELECT
        l.borough,
        'ACE Violations' AS series,
        COUNT(*) AS event_count
    FROM `riya-gcp-1.nyc_illegal_parking_marts.fact_ace_violations` f
    JOIN `riya-gcp-1.nyc_illegal_parking_marts.dim_location_project` l
        ON f.location_key = l.location_key
    GROUP BY l.borough

    UNION ALL

    SELECT
        l.borough,
        '311 Complaints' AS series,
        COUNT(*) AS event_count
    FROM `riya-gcp-1.nyc_illegal_parking_marts.fact_311_complaints` f
    JOIN `riya-gcp-1.nyc_illegal_parking_marts.dim_location_project` l
        ON f.location_key = l.location_key
    GROUP BY l.borough
)
GROUP BY borough, series
ORDER BY borough, series;

-- Q2: Compares yearly ACE violations and 311 complaints.
-- This gives a time-based view of whether enforcement and public complaints
-- move together over time.

SELECT
    year,
    series,
    SUM(event_count) AS event_count
FROM (
    SELECT
        d.year,
        'ACE Violations' AS series,
        COUNT(*) AS event_count
    FROM `riya-gcp-1.nyc_illegal_parking_marts.fact_ace_violations` f
    JOIN `riya-gcp-1.nyc_illegal_parking_marts.dim_date_project` d
        ON f.date_key = d.date_key
    GROUP BY d.year

    UNION ALL

    SELECT
        d.year,
        '311 Complaints' AS series,
        COUNT(*) AS event_count
    FROM `riya-gcp-1.nyc_illegal_parking_marts.fact_311_complaints` f
    JOIN `riya-gcp-1.nyc_illegal_parking_marts.dim_date_project` d
        ON f.date_key = d.date_key
    GROUP BY d.year
)
GROUP BY year, series
ORDER BY year, series;

-- Q3: Monthly trend comparing ACE violations and 311 complaints.
-- This helps identify when illegal-parking pressure increased or decreased.

SELECT
    month_start,
    series,
    SUM(event_count) AS event_count
FROM (
    SELECT
        DATE_TRUNC(d.full_date, MONTH) AS month_start,
        'ACE Violations' AS series,
        COUNT(*) AS event_count
    FROM `riya-gcp-1.nyc_illegal_parking_marts.fact_ace_violations` f
    JOIN `riya-gcp-1.nyc_illegal_parking_marts.dim_date_project` d
        ON f.date_key = d.date_key
    GROUP BY month_start

    UNION ALL

    SELECT
        DATE_TRUNC(d.full_date, MONTH) AS month_start,
        '311 Complaints' AS series,
        COUNT(*) AS event_count
    FROM `riya-gcp-1.nyc_illegal_parking_marts.fact_311_complaints` f
    JOIN `riya-gcp-1.nyc_illegal_parking_marts.dim_date_project` d
        ON f.date_key = d.date_key
    GROUP BY month_start
)
GROUP BY month_start, series
ORDER BY month_start, series;

-- Q4: Compares ACE violations and 311 complaints by day of week.
-- This supports operational analysis by showing when curb conflict is highest.

SELECT
    day_of_week,
    series,
    SUM(event_count) AS event_count
FROM (
    SELECT
        d.day_of_week,
        'ACE Violations' AS series,
        COUNT(*) AS event_count
    FROM `riya-gcp-1.nyc_illegal_parking_marts.fact_ace_violations` f
    JOIN `riya-gcp-1.nyc_illegal_parking_marts.dim_date_project` d
        ON f.date_key = d.date_key
    GROUP BY d.day_of_week

    UNION ALL

    SELECT
        d.day_of_week,
        '311 Complaints' AS series,
        COUNT(*) AS event_count
    FROM `riya-gcp-1.nyc_illegal_parking_marts.fact_311_complaints` f
    JOIN `riya-gcp-1.nyc_illegal_parking_marts.dim_date_project` d
        ON f.date_key = d.date_key
    GROUP BY d.day_of_week
)
GROUP BY day_of_week, series
ORDER BY day_of_week, series;

-- Q5: Shows the distribution of ACE violation categories by borough.
-- This explains what kind of illegal parking behavior is most common
-- in each borough.

SELECT
    l.borough,
    vt.violation_category,
    COUNT(*) AS violation_count,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (PARTITION BY l.borough),
        2
    ) AS borough_share
FROM `riya-gcp-1.nyc_illegal_parking_marts.fact_ace_violations` f
JOIN `riya-gcp-1.nyc_illegal_parking_marts.dim_location_project` l
    ON f.location_key = l.location_key
JOIN `riya-gcp-1.nyc_illegal_parking_marts.dim_ace_violation_type` vt
    ON f.violation_type_key = vt.violation_type_key
GROUP BY
    l.borough,
    vt.violation_category
ORDER BY
    l.borough,
    borough_share DESC;


-- ScoreCards
SELECT COUNT(*) AS total_ace_violations
FROM `riya-gcp-1.nyc_illegal_parking_marts.fact_ace_violations`

SELECT COUNT(*) AS total_311_complaints
FROM `riya-gcp-1.nyc_illegal_parking_marts.fact_311_complaints`