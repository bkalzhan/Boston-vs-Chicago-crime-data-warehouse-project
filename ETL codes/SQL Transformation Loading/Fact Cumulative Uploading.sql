-------Uploading COMMON_CRIME fact Table------
--create staging table--
CREATE TABLE Common_Crime_Staging (
	Staging_ID SERIAL PRIMARY KEY,
    Crime_Type_id INT,
    Date_id INT,
    LOC_ID INT,
    City_Id INT,
    Total_Crime_Count INT,
    Crime_Type_Count INT,
    City_Crime_Ratio DECIMAL(10, 5),
    Crime_Frequency DECIMAL(10, 5)
);

SELECT * FROM City;

--prepare data--
SELECT 
    bs.Crime_Type_id,
    bs.Date_id,
    bs.LOC_ID,
    COUNT(*) OVER (PARTITION BY bs.Date_id, bs.LOC_ID) AS Total_Crime_Count,
    COUNT(bs.CRIME_TYPE_ID) AS Crime_Type_Count,
    ROUND(CAST(COUNT(bs.CRIME_TYPE_ID) AS DECIMAL) / 
          SUM(COUNT(*)) OVER (), 5) AS City_Crime_Ratio,
    ROUND(CAST(COUNT(bs.CRIME_TYPE_ID) AS DECIMAL) / 
          COUNT(*) OVER (PARTITION BY bs.Date_id, bs.LOC_ID), 5) AS Crime_Frequency
FROM 
    Boston_Staging bs
GROUP BY 
    bs.Crime_Type_id, bs.Date_id, bs.LOC_ID;

--transfer from Boston_Staging to common_staging--
INSERT INTO Common_Crime_Staging (
    Crime_Type_id,
    Date_id,
    LOC_ID,
    City_Id,
    Total_Crime_Count,
    Crime_Type_Count,
    City_Crime_Ratio,
    Crime_Frequency
)
SELECT 
    bs.Crime_Type_id,
    bs.Date_id,
    bs.LOC_ID,
    1 AS City_Id, -- Assuming '1' as a placeholder for city identifier
    COUNT(*) OVER (PARTITION BY bs.Date_id, bs.LOC_ID) AS Total_Crime_Count,
    COUNT(bs.CRIME_TYPE_ID) AS Crime_Type_Count,
    ROUND(CAST(COUNT(bs.CRIME_TYPE_ID) AS DECIMAL) / 
          SUM(COUNT(*)) OVER (), 5) AS City_Crime_Ratio,
    ROUND(CAST(COUNT(bs.CRIME_TYPE_ID) AS DECIMAL) / 
          COUNT(*) OVER (PARTITION BY bs.Date_id, bs.LOC_ID), 5) AS Crime_Frequency
FROM 
    Boston_Staging bs
GROUP BY 
    bs.Crime_Type_id, bs.Date_id, bs.LOC_ID;

SELECT * FROM Common_Crime_Staging;

--Check duplicates--
SELECT 
    Crime_Type_id,
    Date_id,
    LOC_ID,
    City_Id,
    COUNT(*) AS Duplicate_Count
FROM 
    Common_Crime_Staging
GROUP BY 
    Crime_Type_id, Date_id, LOC_ID, City_Id
HAVING 
    COUNT(*) > 1;



--transfer from Chicago to common_staging--
SELECT 
    cs.Crime_type_id,
    cs.Date_id,
    cs.Loc_id,
    2 AS City_Id,
    COUNT(*) OVER (PARTITION BY cs.Date_id, cs.Loc_id) AS Total_Crime_Count,
    COUNT(*) OVER (PARTITION BY cs.Date_id, cs.Loc_id, cs.Crime_type_id) AS Crime_Type_Count,
    ROUND(CAST(COUNT(*) OVER (PARTITION BY cs.Date_id, cs.Loc_id, cs.Crime_type_id) AS DECIMAL) 
          / NULLIF(COUNT(*) OVER (PARTITION BY cs.Date_id, cs.Loc_id), 0), 5) AS City_Crime_Ratio,
    ROUND(CAST(COUNT(*) OVER (PARTITION BY cs.Date_id, cs.Crime_type_id) AS DECIMAL) 
          / NULLIF(COUNT(*) OVER (PARTITION BY cs.Date_id), 0), 5) AS Crime_Frequency
FROM 
    Chicago_staging cs
WHERE 
    cs.Crime_type_id IS NOT NULL
    AND cs.Date_id IS NOT NULL
    AND cs.Loc_id IS NOT NULL;

INSERT INTO Common_Crime_Staging (
    Crime_Type_id,
    Date_id,
    LOC_ID,
    City_Id,
    Total_Crime_Count,
    Crime_Type_Count,
    City_Crime_Ratio,
    Crime_Frequency
)
SELECT 
    cs.Crime_type_id,
    cs.Date_id,
    cs.Loc_id,
    2 AS City_Id,
    COUNT(*) OVER (PARTITION BY cs.Date_id, cs.Loc_id) AS Total_Crime_Count,
    COUNT(*) OVER (PARTITION BY cs.Date_id, cs.Loc_id, cs.Crime_type_id) AS Crime_Type_Count,
    ROUND(CAST(COUNT(*) OVER (PARTITION BY cs.Date_id, cs.Loc_id, cs.Crime_type_id) AS DECIMAL) 
          / NULLIF(COUNT(*) OVER (PARTITION BY cs.Date_id, cs.Loc_id), 0), 5) AS City_Crime_Ratio,
    ROUND(CAST(COUNT(*) OVER (PARTITION BY cs.Date_id, cs.Crime_type_id) AS DECIMAL) 
          / NULLIF(COUNT(*) OVER (PARTITION BY cs.Date_id), 0), 5) AS Crime_Frequency
FROM 
    Chicago_staging cs
WHERE 
    cs.Crime_type_id IS NOT NULL
    AND cs.Date_id IS NOT NULL
    AND cs.Loc_id IS NOT NULL;

--Check duplicates--
SELECT 
    Crime_Type_id,
    Date_id,
    LOC_ID,
    City_Id,
    COUNT(*) AS Duplicate_Count
FROM 
    Common_Crime_Staging
GROUP BY 
    Crime_Type_id, Date_id, LOC_ID, City_Id
HAVING 
    COUNT(*) > 1;

--remove duplicates
WITH CTE AS (
    SELECT
        Staging_ID,
        ROW_NUMBER() OVER (
            PARTITION BY Crime_Type_id, Date_id, LOC_ID, City_Id
            ORDER BY Staging_ID
        ) AS row_num
    FROM Common_Crime_Staging
)
DELETE FROM Common_Crime_Staging
WHERE Staging_ID IN (
    SELECT Staging_ID
    FROM CTE
    WHERE row_num > 1
);

SELECT Count(*) FROM Common_Crime_Staging;
SELECT * FROM Common_Crime_Staging;



---- Transfering from Staging table to COMMON_CRIME----
INSERT INTO Common_Crime (
    Crime_Type_id, 
    Date_id, 
    LOC_ID, 
    City_Id, 
    Total_Crime_Count, 
    Crime_Type_Count, 
    City_Crime_Ratio, 
    Crime_Frequency
)
SELECT 
    Crime_Type_id, 
    Date_id, 
    LOC_ID, 
    City_Id, 
    Total_Crime_Count, 
    Crime_Type_Count, 
    City_Crime_Ratio, 
    Crime_Frequency
FROM Common_Crime_Staging
ON CONFLICT (Crime_Type_id, Date_id, LOC_ID, City_Id) DO NOTHING;



----DAY OF WEEK TABLE UPLOADING----
CREATE TABLE Day_of_Week_Crime_Staging (
    Staging_ID SERIAL PRIMARY KEY, -- Unique identifier
    City_id INT NOT NULL, -- Foreign key to City table
    Day_of_week VARCHAR(10) NOT NULL, -- Foreign key to Day table
	Crime_type_id INT NOT NULL,
	Crime_count INT,
	Day_id INT
);

INSERT INTO Day_of_Week_Crime_Staging (
    City_id,
    Day_of_week,
    Crime_type_id,
    Crime_count
)
SELECT
    1 AS City_id, -- Boston's City ID
    bs.DAY_OF_WEEK AS Day_of_week, -- Day of the week
    bs.Crime_type_id, -- Crime type ID
    1 AS Crime_count -- Count of crimes by type and day
FROM
    Boston_staging bs;


INSERT INTO Day_of_Week_Crime_Staging (
    City_id,
    Day_of_week,
    Crime_type_id,
    Crime_count
)
SELECT
    2 AS City_id, -- Chicago's City ID
    cs.DAY_OF_WEEK AS Day_of_week, -- Day of the week
    cs.Crime_type_id, -- Crime type ID
    1 AS Crime_count -- Count of crimes by type and day
FROM
    Chicago_staging cs;

SELECT * FROM Day_of_Week_Crime_Staging;

--Insert day_ids--
UPDATE Day_of_Week_Crime_Staging staging
SET Day_id = day_table.day_id
FROM Day day_table
WHERE staging.Day_of_week = day_table.Day_of_week;

SELECT * FROM Day;



--prepare data--
WITH TotalCrimes AS (
    SELECT
        City_id,
        Day_of_week,
        SUM(Crime_count) AS Total_Crime_Count
    FROM
        Day_of_Week_Crime_Staging
    GROUP BY
        City_id, Day_of_week
),
RankedCrimes AS (
    SELECT
        staging.City_id,
        staging.Day_of_week,
        staging.Crime_Type_id,
        tc.Total_Crime_Count,
        COUNT(staging.Crime_Type_id) AS Crime_Type_Count,
        RANK() OVER (PARTITION BY staging.City_id, staging.Day_of_week ORDER BY COUNT(staging.Crime_Type_id) DESC) AS Crime_Type_Rank
    FROM 
        Day_of_Week_Crime_Staging staging
    JOIN
        TotalCrimes tc
    ON
        staging.City_id = tc.City_id AND staging.Day_of_week = tc.Day_of_week
    GROUP BY 
        staging.City_id, 
        staging.Day_of_week, 
        staging.Crime_Type_id, 
        tc.Total_Crime_Count
)
SELECT
    City_id,
    Day_of_week,
    Crime_Type_id,
    Total_Crime_Count,
    Crime_Type_Count
FROM
    RankedCrimes
WHERE
    Crime_Type_Rank = 1
ORDER BY 
    City_id, 
    Day_of_week;


--insert data--
WITH TotalCrimes AS (
    SELECT
        City_id,
        Day_of_week,
        SUM(Crime_count) AS Total_Crime_Count
    FROM
        Day_of_Week_Crime_Staging
    GROUP BY
        City_id, Day_of_week
),
RankedCrimes AS (
    SELECT
        staging.City_id,
        staging.Day_of_week,
        staging.Crime_Type_id,
        tc.Total_Crime_Count,
        COUNT(staging.Crime_Type_id) AS Crime_Type_Count,
        RANK() OVER (PARTITION BY staging.City_id, staging.Day_of_week ORDER BY COUNT(staging.Crime_Type_id) DESC) AS Crime_Type_Rank,
        MAX(COUNT(staging.Crime_Type_id)) OVER (PARTITION BY staging.City_id, staging.Day_of_week) AS Most_Common_Crime_Count
    FROM 
        Day_of_Week_Crime_Staging staging
    JOIN
        TotalCrimes tc
    ON
        staging.City_id = tc.City_id AND staging.Day_of_week = tc.Day_of_week
    GROUP BY 
        staging.City_id, 
        staging.Day_of_week, 
        staging.Crime_Type_id, 
        tc.Total_Crime_Count
)
INSERT INTO Day_of_Week_Crime (
    City_id, 
    Day_id,
    Avg_crimes_per_day,
    Crime_total_count_per_day,
    Most_common_crime_Type,
    Most_common_crime_count,
    Most_common_crime_percentage
)
SELECT
    rc.City_id,
    d.Day_id,  -- Assume Day table has Day_id that corresponds to Day_of_week
    CASE 
        WHEN rc.City_id = 1 THEN rc.Total_Crime_Count / 99
        WHEN rc.City_id = 2 THEN rc.Total_Crime_Count / 47
        ELSE rc.Total_Crime_Count / 100  -- Default for other cities, adjust as needed
    END AS Avg_crimes_per_day,
    rc.Total_Crime_Count AS Crime_total_count_per_day,
    rc.Crime_Type_id AS Most_common_crime_Type,
    rc.Most_Common_Crime_Count AS Most_common_crime_count,
    rc.Most_Common_Crime_Count * 1.0 / rc.Total_Crime_Count AS Most_common_crime_percentage
FROM
    RankedCrimes rc
JOIN
    Day d ON d.Day_of_week = rc.Day_of_week  -- Join with Day table to get Day_id
WHERE
    rc.Crime_Type_Rank = 1
ORDER BY
    rc.City_id, rc.Day_of_week;



SELECT * FROM day_of_week_crime;




----HOUR OF DAY TABLE UPLOADING----

CREATE TABLE Hour_of_Day_Crime_Staging (
	Crime_Type_id INT,
	Loc_id INT,
	City_id INT,
	Time_id INT,
	Crime_count INT
)

INSERT INTO Hour_of_Day_Crime_Staging (
    Crime_Type_id,
    Loc_id,
    City_id,
    Time_id,
    Crime_count
)
SELECT
    bs.Crime_Type_id,   -- Crime type from Boston_staging
    bs.Loc_id,          -- Location ID
    1 AS City_id,       -- Assuming Boston has City_id = 1
    t.Time_id,          -- Time_id from Time table
    1 AS Crime_count    -- Assuming each row in Boston_staging represents 1 crime
FROM
    Boston_staging bs
JOIN
    Time t ON t.Hour = bs.Hour; -- Match Hour from Boston_staging with Hour in Time table


INSERT INTO Hour_of_Day_Crime_Staging (
    Crime_Type_id,
    Loc_id,
    City_id,
    Time_id,
    Crime_count
)
SELECT
    cs.Crime_Type_id,
    cs.Loc_id,
    2 AS City_id,
    t.Time_id,
    1 AS Crime_count
FROM
    Chicago_staging cs
JOIN
    Time t ON t.Hour = cs.Hour;

SELECT * FROM Hour_of_Day_Crime_Staging;

--Inserting data into FACT table--
WITH TotalCrimes AS (
    SELECT
        City_id,
        Time_id,
        SUM(Crime_count) AS Total_Crime_Count
    FROM
        Hour_of_Day_Crime_Staging
    GROUP BY
        City_id, Time_id
),
CrimeTypeStats AS (
    SELECT
        City_id,
        Time_id,
        Crime_Type_id,
        COUNT(*) AS Crime_Type_Count,
        RANK() OVER (
            PARTITION BY City_id, Time_id 
            ORDER BY COUNT(*) DESC
        ) AS Crime_Type_Rank
    FROM
        Hour_of_Day_Crime_Staging
    GROUP BY
        City_id, Time_id, Crime_Type_id
)
INSERT INTO Hour_of_Day_Crime (
    City_Id,
    Time_id,
    Total_Crime_Count,
    Avg_Crimes_Per_Hour,
    Most_Common_Crime,
    Most_Crime_Type_Count,
    Common_Crime_Percentage
)
SELECT
    staging.City_id,
    staging.Time_id,
    tc.Total_Crime_Count,
    CASE 
        WHEN staging.City_id = 1 THEN (tc.Total_Crime_Count / 691.0) 
        WHEN staging.City_id = 2 THEN (tc.Total_Crime_Count / 330.0)
        ELSE NULL
    END AS Avg_Crimes_Per_Hour,
    cts.Crime_Type_id AS Most_Common_Crime,
    cts.Crime_Type_Count AS Most_Crime_Type_Count,
    (cts.Crime_Type_Count::DECIMAL / tc.Total_Crime_Count) AS Common_Crime_Percentage
FROM
    Hour_of_Day_Crime_Staging staging
JOIN
    TotalCrimes tc
ON
    staging.City_id = tc.City_id AND staging.Time_id = tc.Time_id
JOIN
    CrimeTypeStats cts
ON
    staging.City_id = cts.City_id 
    AND staging.Time_id = cts.Time_id
    AND cts.Crime_Type_Rank = 1
GROUP BY
    staging.City_id,
    staging.Time_id,
    tc.Total_Crime_Count,
    cts.Crime_Type_id,
    cts.Crime_Type_Count
ORDER BY
    staging.City_id, staging.Time_id;


SELECT * FROM Hour_of_Day_Crime;


WITH TotalCrimes AS (
    SELECT
        City_id,
        Time_id,
        SUM(Crime_count) AS Total_Crime_Count -- Total crimes for each city and hour
    FROM
        Hour_of_Day_Crime_Staging
    GROUP BY
        City_id, Time_id
),
CrimeTypeStats AS (
    SELECT
        City_id,
        Time_id,
        Crime_Type_id,
        COUNT(*) AS Crime_Type_Count, -- Count of this crime type
        RANK() OVER (
            PARTITION BY City_id, Time_id 
            ORDER BY COUNT(*) DESC
        ) AS Crime_Type_Rank -- Rank crimes by frequency
    FROM
        Hour_of_Day_Crime_Staging
    GROUP BY
        City_id, Time_id, Crime_Type_id
)
SELECT
    staging.City_id,
    staging.Time_id,
    tc.Total_Crime_Count, -- Total crimes per city and hour
    CASE 
        WHEN staging.City_id = 1 THEN (tc.Total_Crime_Count / 691.0) 
        WHEN staging.City_id = 2 THEN (tc.Total_Crime_Count / 330.0)
        ELSE tc.Total_Crime_Count
    END AS Avg_Crimes_Per_Hour,
    cts.Crime_Type_id AS Most_Common_Crime_Type, -- Crime type with rank 1
    cts.Crime_Type_Count AS Most_Common_Crime_Count,
    (cts.Crime_Type_Count::DECIMAL / tc.Total_Crime_Count) AS Common_Crime_Percentage
FROM
    Hour_of_Day_Crime_Staging staging
JOIN
    TotalCrimes tc
ON
    staging.City_id = tc.City_id AND staging.Time_id = tc.Time_id
JOIN
    CrimeTypeStats cts
ON
    staging.City_id = cts.City_id 
    AND staging.Time_id = cts.Time_id
    AND cts.Crime_Type_Rank = 1 -- Filter for the most common crime
GROUP BY
    staging.City_id,
    staging.Time_id,
    tc.Total_Crime_Count,
    cts.Crime_Type_id,
    cts.Crime_Type_Count
ORDER BY
    staging.City_id, staging.Time_id;

