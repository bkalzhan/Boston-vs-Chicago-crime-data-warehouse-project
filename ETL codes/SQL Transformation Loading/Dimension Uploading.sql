----------------------------Uploading Process----------------------------

--------------Uploading Dimensional Tables--------------

-----Uploading Crime_Type dimensional Table----

-- Create a temporary staging table to hold the new data from the CSV file
CREATE TABLE crime_type_staging (
    Crime_code VARCHAR(10) NOT NULL,
    Crime_description VARCHAR(255) NOT NULL
);

-- IMPORTANT: Loading CSV data into the staging table --
SELECT COUNT(*) FROM crime_type_staging;
SELECT * FROM crime_type_staging;

-- Process loading data into final table
DO $$
DECLARE
    rec RECORD;
BEGIN
    -- Loop through each record in the staging table
    FOR rec IN 
        SELECT Crime_code, Crime_description 
        FROM crime_type_staging
    LOOP
        -- Check if the crime code exists with "Current" status
        IF EXISTS (
            SELECT 1
            FROM crime_type
            WHERE Crime_code = rec.Crime_code
              AND Status = 'Current'
        ) THEN
            -- Compare the descriptions for the current record
            IF NOT EXISTS (
                SELECT 1
                FROM crime_type
                WHERE Crime_code = rec.Crime_code
                  AND Crime_description = rec.Crime_description
                  AND Status = 'Current'
            ) THEN
                -- Update the current record to "Expired" and set Expiration_date to today
                UPDATE crime_type
                SET Status = 'Expired',
                    Expiration_date = CURRENT_DATE
                WHERE Crime_code = rec.Crime_code
                  AND Status = 'Current';

                -- Insert the new record as "Current"
                INSERT INTO crime_type (Crime_code, Crime_description, Effective_date, Expiration_date, Status)
                VALUES (rec.Crime_code, rec.Crime_description, CURRENT_DATE, '9999-12-31', 'Current');
            END IF;
        ELSE
            -- If the crime code doesn't exist, insert it as "Current"
            INSERT INTO crime_type (Crime_code, Crime_description, Effective_date, Expiration_date, Status)
            VALUES (rec.Crime_code, rec.Crime_description, CURRENT_DATE, '9999-12-31', 'Current');
        END IF;
    END LOOP;
END $$;


SELECT DISTINCT(crime_code) FROM crime_type;
SELECT COUNT(*) FROM crime_type;




----------SECOND OPTION-------
-- 1. Expire current records where descriptions are different
UPDATE crime_type
SET Status = 'Expired',
    Expiration_date = CURRENT_DATE
FROM crime_type_staging staging
WHERE crime_type.Crime_code = staging.Crime_code
  AND crime_type.Status = 'Current'
  AND crime_type.Crime_description <> staging.Crime_description;

-- 2. Insert new records for updated or new crimes
INSERT INTO crime_type (Crime_code, Crime_description, Effective_date, Expiration_date, Status)
SELECT staging.Crime_code, staging.Crime_description, CURRENT_DATE, '9999-12-31', 'Current'
FROM crime_type_staging staging
LEFT JOIN crime_type current
  ON staging.Crime_code = current.Crime_code
     AND current.Status = 'Current'
WHERE current.Crime_code IS NULL
   OR current.Crime_description <> staging.Crime_description;

-- 3. Insert completely new records
INSERT INTO crime_type (Crime_code, Crime_description, Effective_date, Expiration_date, Status)
SELECT Crime_code, Crime_description, CURRENT_DATE, '9999-12-31', 'Current'
FROM crime_type_staging staging
WHERE NOT EXISTS (
    SELECT 1
    FROM crime_type
    WHERE crime_type.Crime_code = staging.Crime_code
);

-- Drop the temporary staging table after processing
DROP TABLE crime_type_staging;





-----Uploading DATE dimensional Table----

-- Create a temporary staging table to hold the new data from the CSV file
CREATE TABLE date_staging (
	Year INT NOT NULL,
	Month INT NOT NULL CHECK (Month BETWEEN 1 AND 12),
	Day INT NOT NULL CHECK (Day BETWEEN 1 AND 31)
);

-- IMPORTANT: Loading CSV data into the staging table --
SELECT COUNT(*) FROM date_staging;
SELECT * FROM date_staging;

-- Insert new records into the Date table
INSERT INTO Date (year, month, day)
SELECT s.year, s.month, s.day
FROM date_staging s
LEFT JOIN Date d
ON s.year = d.year AND s.month = d.month AND s.day = d.day
WHERE d.year IS NULL;

SELECT * FROM Date;

-- Drop the temporary staging table after processing
DROP TABLE date_staging;

-----Uploading Month-----
INSERT INTO Month (Year, Month)
SELECT DISTINCT Year, Month
FROM Date;

SELECT * FROM Month;

-----Uploading LOCATION dimensional Table----

-- Create a temporary staging table to hold the new data from the CSV file
CREATE TABLE Location_Staging (
    District VARCHAR(50),
    Street VARCHAR(100),
    Ward INT,
    Community_area INT
);

-- IMPORTANT: Loading CSV data into the staging table --
SELECT COUNT(*) FROM Location_Staging;
SELECT * FROM Location_Staging;

-- Insert or update records in the Location table
WITH upsert AS (
    -- Update existing rows if there's a change
    UPDATE Location
    SET 
        Ward = st.Ward,
        Community_area = st.Community_area
    FROM Location_Staging st
    WHERE Location.Street = st.Street  -- Match on specific Street
      AND Location.District = st.District -- Match on District
      AND (Location.Ward IS DISTINCT FROM st.Ward
           OR Location.Community_area IS DISTINCT FROM st.Community_area)
    RETURNING Location.Loc_id
)
-- Insert rows not in the Location table
INSERT INTO Location (District, Street, Ward, Community_area)
SELECT st.District, st.Street, st.Ward, st.Community_area
FROM Location_Staging st
LEFT JOIN Location loc
ON st.Street = loc.Street AND st.District = loc.District
WHERE loc.Loc_id IS NULL;

SELECT * FROM Location;

-- Drop the temporary staging table after processing
DROP TABLE Location_Staging;

--Handlenull values for distric column--
UPDATE Location SET district = '' WHERE district IS NULL;



-----Uploading Time dimensional Table----
INSERT INTO Time (Hour)
SELECT generate_series(0, 23);

SELECT * FROM Time;






-----Uploading Reporting_Area dimensional Table----

-- Create a temporary staging table to hold the new data from the CSV file
CREATE TABLE Reporting_Area_Staging (
    Code VARCHAR(50) NOT NULL UNIQUE
);

-- IMPORTANT: Loading CSV data into the staging table --
SELECT COUNT(*) FROM Reporting_Area_Staging;
SELECT * FROM Reporting_Area_Staging;

-- Insert or update records in the Location table
MERGE INTO Reporting_Area r
USING Reporting_Area_Staging s ON r.code = s.code
WHEN NOT MATCHED THEN
   INSERT (code)
   VALUES(s.code)
WHEN MATCHED THEN
   DO NOTHING;

SELECT COUNT(*) FROM Reporting_Area;
SELECT * FROM Reporting_Area;

-- Drop the temporary staging table after processing
DROP TABLE Reporting_Area_Staging;






-----Uploading DAY dimensional Table----

-- Create a temporary staging table to hold the new data from the CSV file
CREATE TABLE day_staging (
    Year INT,
    Month INT,
    Day INT,
    Day_of_week VARCHAR(10)
);

-- IMPORTANT: Loading CSV data into the staging table --
SELECT COUNT(*) FROM day_staging;
SELECT DISTINCT YEAR FROM day_staging;

-- Insert or update records in the Location table
INSERT INTO Day (Year, Month, Day, Day_of_week)
SELECT Year, Month, Day, Day_of_week
FROM day_staging
ON CONFLICT DO NOTHING;

SELECT COUNT(*) FROM Day;
SELECT DISTINCT DAY_OF_WEEK FROM Day;

-- Drop the temporary staging table after processing
DROP TABLE day_staging;



-----Uploading CITY dimensional Table----

CREATE TABLE City_staging(
	Original_ID INT,
    City_name VARCHAR(100) NOT NULL
)

INSERT INTO City_staging (Original_ID, City_name) VALUES(1, 'Boston');
INSERT INTO City_staging (Original_ID, City_name) VALUES(2, 'Chicago');
-- INSERT INTO City_staging (Original_ID, City_name) VALUES(3, 'New York');
INSERT INTO City_staging (Original_ID, City_name) VALUES(3, 'New Jersey');
INSERT INTO City_staging (Original_ID, City_name) VALUES(4, 'Cambridge');

DROP TABLE City_staging;

SELECT * FROM City_staging;
SELECT * FROM City;

-- Insert new records into the City table if Original_ID does not exist
INSERT INTO City (Original_ID, Current_name)
SELECT 
    s.Original_ID,
    s.city_name
FROM 
    city_staging s
WHERE NOT EXISTS (
    SELECT 1
    FROM City c
    WHERE c.Original_ID = s.Original_ID
);

-- Update records in the City table where there is a match in Original_ID
UPDATE City
SET 
    "2024_City_name" = Current_name,  -- Move current name to 2024_City_name
    Current_name = (
        SELECT s.city_name
        FROM city_staging s
        WHERE s.Original_ID = City.Original_ID
    )
WHERE EXISTS (
    SELECT 1
    FROM city_staging s
    WHERE s.Original_ID = City.Original_ID
      AND s.city_name != City.Current_name
);


