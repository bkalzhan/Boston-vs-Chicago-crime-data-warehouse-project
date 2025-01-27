-------------Analytical Queries---------------
-------0th query------
WITH CrimeSummary AS (
    SELECT 
        ct.Crime_description,
        c.City_Id,
        c.current_name,
        SUM(bc.Crime_Count) AS Total_Boston_Crimes,
        SUM(cc.Crime_Count) AS Total_Chicago_Crimes
    FROM 
        Crime_Type ct
    LEFT JOIN Boston_Crime bc ON ct.Crime_Type_id = bc.Crime_Type_id
    LEFT JOIN Chicago_Crime cc ON ct.Crime_Type_id = cc.Crime_Type_id
    JOIN City c ON (c.City_Id = 1 AND bc.Boston_Crime_id IS NOT NULL) OR (c.City_Id = 2 AND cc.Crime_ID IS NOT NULL)
    GROUP BY 
        ct.Crime_description, c.City_Id, c.current_name
),
RankedCrimes AS (
    SELECT 
        Crime_description,
        current_name,
        Total_Boston_Crimes,
        Total_Chicago_Crimes,
        RANK() OVER (PARTITION BY current_name ORDER BY Total_Boston_Crimes DESC NULLS LAST) AS Boston_Rank,
        RANK() OVER (PARTITION BY current_name ORDER BY Total_Chicago_Crimes DESC NULLS LAST) AS Chicago_Rank
    FROM 
        CrimeSummary
)
SELECT 
    Crime_description,
    current_name,
    Total_Boston_Crimes,
    Total_Chicago_Crimes,
    Boston_Rank,
    Chicago_Rank
FROM 
    RankedCrimes
WHERE 
    Boston_Rank <= 5 OR Chicago_Rank <= 5
ORDER BY 
    current_name, Boston_Rank, Chicago_Rank;




--------1st query--------------
--Chicago--
WITH Crime_Summary AS (
    SELECT 
        ct.Crime_description AS Crime_Type,
        SUM(cc.Crime_Count) AS Total_Crime_Count
    FROM 
        Chicago_Crime cc
    JOIN 
        Crime_Type ct ON cc.Crime_Type_id = ct.Crime_Type_id
    GROUP BY 
        ct.Crime_description
),
Ranked_Crimes AS (
    SELECT 
        Crime_Type,
        Total_Crime_Count,
        RANK() OVER (ORDER BY Total_Crime_Count DESC) AS Crime_Rank,
        SUM(Total_Crime_Count) OVER () AS Total_Crime_Global,
        ROUND((SUM(Total_Crime_Count) OVER (PARTITION BY Crime_Type) * 100.0) 
              / SUM(Total_Crime_Count) OVER (), 2) AS Percentage_Contribution
    FROM 
        Crime_Summary
)
SELECT 
    Crime_Type,
    Total_Crime_Count,
    Percentage_Contribution,
    Crime_Rank
FROM 
    Ranked_Crimes
WHERE 
    Total_Crime_Count > 10000
ORDER BY 
    Crime_Rank
LIMIT 10;


SELECT * 
FROM Crime_Type 
WHERE Crime_code LIKE '38%';

--Boston--
WITH Crime_Summary AS (
    SELECT 
        ct.Crime_description AS Crime_Type,
        SUM(cc.Crime_Count) AS Total_Crime_Count
    FROM 
        Boston_Crime cc
    JOIN 
        Crime_Type ct ON cc.Crime_Type_id = ct.Crime_Type_id
    GROUP BY 
        ct.Crime_description
),
Ranked_Crimes AS (
    SELECT 
        Crime_Type,
        Total_Crime_Count,
        RANK() OVER (ORDER BY Total_Crime_Count DESC) AS Crime_Rank,
        SUM(Total_Crime_Count) OVER () AS Total_Crime_Global,
        ROUND((SUM(Total_Crime_Count) OVER (PARTITION BY Crime_Type) * 100.0) 
              / SUM(Total_Crime_Count) OVER (), 2) AS Percentage_Contribution
    FROM 
        Crime_Summary
)
SELECT 
    Crime_Type,
    Total_Crime_Count,
    Percentage_Contribution,
    Crime_Rank
FROM 
    Ranked_Crimes
WHERE 
    Total_Crime_Count > 1000
ORDER BY 
    Crime_Rank
LIMIT 10;


-------2nd query-----------
--Chicago--
SELECT
    loc.LOC_ID,
	loc.district,
	loc.ward,
	loc.community_area,
	loc.street,
	loc.district || '_' || loc.ward || '_' || loc.community_area || '_' || loc.street AS Location,
    Most_Common_Crime_Type,
    Total_Crimes
FROM (
    SELECT
        cc.LOC_ID,
        ct.Crime_description AS Most_Common_Crime_Type,
        COUNT(cc.CRIME_ID) AS Crime_Type_Count,
        SUM(COUNT(cc.CRIME_ID)) OVER (PARTITION BY cc.LOC_ID) AS Total_Crimes,
        ROW_NUMBER() OVER (PARTITION BY cc.LOC_ID ORDER BY COUNT(cc.CRIME_ID) DESC) AS Crime_Rank
    FROM
        Chicago_Crime cc
    JOIN
        Crime_Type ct ON cc.Crime_Type_id = ct.Crime_Type_id
    GROUP BY
        cc.LOC_ID, ct.Crime_description
) Ranked_Crimes
JOIN
    Location loc ON Ranked_Crimes.LOC_ID = loc.LOC_ID
WHERE
    Crime_Rank = 1
ORDER BY
    Total_Crimes DESC
LIMIT 10;

--Boston--
SELECT
    loc.LOC_ID,
	loc.district,
	loc.street,
	loc.district || '_' || loc.street AS Location,
    Most_Common_Crime_Type,
    Total_Crimes
FROM (
    SELECT
        cc.LOC_ID,
        ct.Crime_description AS Most_Common_Crime_Type,
        COUNT(cc.CRIME_ID) AS Crime_Type_Count,
        SUM(COUNT(cc.CRIME_ID)) OVER (PARTITION BY cc.LOC_ID) AS Total_Crimes,
        ROW_NUMBER() OVER (PARTITION BY cc.LOC_ID ORDER BY COUNT(cc.CRIME_ID) DESC) AS Crime_Rank
    FROM
        Boston_Crime cc
    JOIN
        Crime_Type ct ON cc.Crime_Type_id = ct.Crime_Type_id
    GROUP BY
        cc.LOC_ID, ct.Crime_description
) Ranked_Crimes
JOIN
    Location loc ON Ranked_Crimes.LOC_ID = loc.LOC_ID
WHERE
    Crime_Rank = 1
ORDER BY
    Total_Crimes DESC
LIMIT 10;



-------3rd query-----------
SELECT d.*, w.day_of_week, c.crime_description  FROM day_of_week_crime d JOIN day w ON d.day_id = w.day_id 
	JOIN crime_type c ON c.crime_type_id = d.most_common_crime_type;

-----most_common_crime_percentage-----
SELECT 
    w.day_of_week,
    MAX(CASE WHEN d.city_id = 1 THEN d.most_common_crime_percentage END) AS Boston,
    MAX(CASE WHEN d.city_id = 2 THEN d.most_common_crime_percentage END) AS Chicago
FROM 
    day_of_week_crime d
JOIN 
    day w ON d.day_id = w.day_id
GROUP BY 
    w.day_of_week
ORDER BY 
    CASE 
        WHEN w.day_of_week = 'Monday' THEN 1
        WHEN w.day_of_week = 'Tuesday' THEN 2
        WHEN w.day_of_week = 'Wednesday' THEN 3
        WHEN w.day_of_week = 'Thursday' THEN 4
        WHEN w.day_of_week = 'Friday' THEN 5
        WHEN w.day_of_week = 'Saturday' THEN 6
        WHEN w.day_of_week = 'Sunday' THEN 7
    END;


----avg_crimes_per_day----
SELECT 
    w.day_of_week,
    MAX(CASE WHEN d.city_id = 1 THEN d.avg_crimes_per_day END) AS Boston,
    MAX(CASE WHEN d.city_id = 2 THEN d.avg_crimes_per_day END) AS Chicago
FROM 
    day_of_week_crime d
JOIN 
    day w ON d.day_id = w.day_id
GROUP BY 
    w.day_of_week
ORDER BY 
    CASE 
        WHEN w.day_of_week = 'Monday' THEN 1
        WHEN w.day_of_week = 'Tuesday' THEN 2
        WHEN w.day_of_week = 'Wednesday' THEN 3
        WHEN w.day_of_week = 'Thursday' THEN 4
        WHEN w.day_of_week = 'Friday' THEN 5
        WHEN w.day_of_week = 'Saturday' THEN 6
        WHEN w.day_of_week = 'Sunday' THEN 7
    END;

SELECT * FROM crime_type where crime_type_id IN (820, 476, 483);

-------4th query--------
SELECT * FROM hour_of_day_crime where city_id = 1;

SELECT 
    time_id AS "Hour",
    MAX(CASE WHEN city_id = 1 THEN common_crime_percentage END) AS Boston,
    MAX(CASE WHEN city_id = 2 THEN common_crime_percentage END) AS Chicago
FROM 
    hour_of_day_crime
GROUP BY 
    time_id
ORDER BY 
    time_id;