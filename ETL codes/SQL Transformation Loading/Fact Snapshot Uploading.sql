--------------Uploading Fact Tables--------------
-------Uploading CHICAGO_CRIME fact Table------
-----Uploading STAGING Table----
--staging table--
CREATE TABLE Chicago_staging (
    Staging_ID SERIAL PRIMARY KEY,
	ID INT,
    Case_Number VARCHAR(50),
    Date TIMESTAMP,
    Year INT,
    Month INT,
    Day INT,
	Day_of_week VARCHAR(10),
    Hour INT,
    Block VARCHAR(100),
    IUCR VARCHAR(10),
    Primary_Type VARCHAR(100),
    Description VARCHAR(255),
	Crime_Description VARCHAR(255),
    Location_Description VARCHAR(255),
    Arrest INT,
    Domestic INT,
    Beat VARCHAR(10),
    District VARCHAR(10),
    Ward INT,
    Community_Area INT,
    FBI_Code VARCHAR(10),
    Updated_On TIMESTAMP,
    Updated_Year INT,
    Updated_Month INT,
    Updated_Day INT,
	Crime_type_id INT,
	Date_id INT,
	Updated_on_id INT,
	Loc_id INT
);

SELECT * FROM Chicago_staging;

----CRIME_TYPE_ID----
--Checking mismathces--
SELECT 
    cs.*
FROM 
    Chicago_staging cs
LEFT JOIN 
    Crime_Type ct
ON 
    cs.IUCR = ct.Crime_code
    AND cs.Crime_Description = ct.Crime_description
WHERE 
    ct.Crime_type_id IS NULL;
--Result was empty--

--Upload CRIME_TYPE_IDs--
UPDATE Chicago_staging
SET Crime_type_id = ct.Crime_type_id
FROM Crime_Type ct
WHERE 
    Chicago_staging.IUCR = ct.Crime_code
    AND Chicago_staging.Crime_Description = ct.Crime_description;

SELECT * FROM Chicago_staging;

----DATE_ID----
--Checking mismathces--
SELECT 
    cs.*
FROM 
    Chicago_staging cs
LEFT JOIN 
    Date d
ON 
    cs.YEAR = d.YEAR
    AND cs.MONTH = d.MONTH
	AND cs.DAY = d.DAY
WHERE 
    d.date_id IS NULL;
--Result was empty--

--Upload DATE_IDs--
UPDATE Chicago_staging
SET date_id = d.date_id
FROM Date d
WHERE 
    Chicago_staging.YEAR = d.YEAR
    AND Chicago_staging.MONTH = d.MONTH
	AND Chicago_staging.DAY = d.DAY;

SELECT * FROM Chicago_staging;
SELECT * FROM Date;

----UPDATED_ON_DATE_ID----
--Checking mismathces--
SELECT 
    cs.*
FROM 
    Chicago_staging cs
LEFT JOIN 
    Date d
ON 
    cs.updated_year = d.YEAR
    AND cs.updated_month = d.MONTH
	AND cs.updated_day = d.DAY
WHERE 
    d.date_id IS NULL;
--Result was empty--

--Upload UODATED_DATE_IDs--
UPDATE Chicago_staging
SET updated_on_id = d.date_id
FROM Date d
WHERE 
    Chicago_staging.updated_year = d.YEAR
    AND Chicago_staging.updated_month = d.MONTH
	AND Chicago_staging.updated_day = d.DAY;


----LOC_ID----
--Checking mismathces--
SELECT 
    cs.*
FROM 
    Chicago_staging cs
LEFT JOIN 
    Location l
ON 
    cs.district = l.district
    AND cs.ward = l.ward
	AND cs.community_area = l.community_area
	AND cs.block = l.street
WHERE 
    l.loc_id IS NULL;
--Result was empty--

--Upload UODATED_DATE_IDs--
UPDATE Chicago_staging
SET loc_id = l.loc_id
FROM Location l
WHERE 
    Chicago_staging.district = l.district
    AND Chicago_staging.ward = l.ward
	AND Chicago_staging.community_area = l.community_area
	AND Chicago_staging.block = l.street;

--checking for duplicates--
SELECT 
    Crime_type_id,
    Date_id,
    Updated_on_id,
    Loc_id,
    COUNT(*)
FROM 
    Chicago_staging
GROUP BY 
    Crime_type_id, 
    Date_id, 
    Updated_on_id, 
    Loc_id
HAVING 
    COUNT(*) > 1;

SELECT COUNT(*)
FROM Chicago_staging
WHERE Staging_ID NOT IN (
    SELECT MIN(Staging_ID)
    FROM Chicago_staging
    GROUP BY Crime_type_id, Date_id, Updated_on_id, Loc_id
);

--removing duplicates--
DELETE FROM Chicago_staging
WHERE Staging_ID NOT IN (
    SELECT MIN(Staging_ID)
    FROM Chicago_staging
    GROUP BY Crime_type_id, Date_id, Updated_on_id, Loc_id
);

--Migrating data from Staging table to Fact table--
INSERT INTO Chicago_Crime (
    Crime_Type_id,
    Date_id,
    Updated_on,
    LOC_ID,
    CRIME_ID,
    Case_Number,
    Crime_Count,
    Arrest,
    Domestic,
    Location_description
)
SELECT
    cs.Crime_type_id,
    cs.Date_id,
    cs.Updated_on_id,
    cs.Loc_id,
    cs.ID, -- Mapping staging ID to CRIME_ID
    cs.Case_Number,
    1 AS Crime_Count, -- Assuming each row represents one crime
    cs.Arrest,
    cs.Domestic,
    cs.Location_Description
FROM
    Chicago_staging cs
WHERE
    cs.Crime_type_id IS NOT NULL
    AND cs.Date_id IS NOT NULL
    AND cs.Updated_on_id IS NOT NULL
    AND cs.Loc_id IS NOT NULL;


-------Uploading BOSTON_CRIME fact Table------
-----Uploading STAGING Table----
--staging table--
CREATE TABLE BOSTON_STAGING (
    ID SERIAL PRIMARY KEY,
    _id INT NOT NULL,
    INCIDENT_NUMBER VARCHAR(50) NOT NULL,
    OFFENCE_CODE VARCHAR(10) NOT NULL,
    OFFENCE_DESCRIPTION VARCHAR(255),
    DISTRICT VARCHAR(10),
    REPORTING_AREA VARCHAR(10),
    SHOOTING INT,
    OCCURED_ON_DATE TIMESTAMP,
    YEAR INT NOT NULL,
    MONTH INT NOT NULL CHECK (MONTH BETWEEN 1 AND 12),
    DAY_OF_WEEK VARCHAR(10),
    HOUR INT CHECK (HOUR BETWEEN 0 AND 23),
    STREET VARCHAR(255),
    DAY INT CHECK (DAY BETWEEN 1 AND 31),
	CRIME_TYPE_ID INT,
	DATE_ID INT,
	LOC_ID INT,
	REP_AREA_ID INT
);

----CRIME_TYPE_ID----
--Checking mismathces--
SELECT 
    bs.*
FROM 
    Boston_staging bs
LEFT JOIN 
    Crime_Type ct
ON 
    bs.offence_code = ct.Crime_code
    AND bs.offence_description = ct.Crime_description
WHERE 
    ct.Crime_type_id IS NULL;
--Result was empty--

--Upload CRIME_TYPE_IDs--
UPDATE Boston_staging
SET Crime_type_id = ct.Crime_type_id
FROM Crime_Type ct
WHERE 
    Boston_staging.offence_code = ct.Crime_code
    AND Boston_staging.offence_description = ct.Crime_description;

----DATE_ID----
--Checking mismathces--
SELECT 
    bs.*
FROM 
    Boston_staging bs
LEFT JOIN 
    DATE D
ON 
    bs.YEAR = D.YEAR
    AND bs.MONTH = D.MONTH
	AND bs.DAY = D.DAY
WHERE 
    D.DATE_ID IS NULL;
--Result was empty--

--Upload DATE_IDs--
UPDATE Boston_staging
SET date_id = d.date_id
FROM Date d
WHERE 
    Boston_staging.year = d.YEAR
    AND Boston_staging.MONTH = d.MONTH
	AND Boston_staging.DAY = d.DAY;

----LOC_ID----
--Checking mismathces--
SELECT 
    bs.*
FROM 
    Boston_staging bs
LEFT JOIN 
    Location l
ON 
    bs.district = l.district
    AND bs.street = l.street
WHERE 
    l.loc_id IS NULL;

--Replace null valuew with empty strings for district column--
UPDATE BOSTON_STAGING SET district=  '' where district IS NULL;

--Upload IDs--
UPDATE Boston_staging
SET loc_id = l.loc_id
FROM Location l
WHERE 
    Boston_staging.district = l.district
    AND Boston_staging.street = l.street
	AND l.ward = 0 AND l.community_area = 0;


----Reporting_area_ID----
--Checking mismathces--
SELECT 
    bs.*
FROM 
    Boston_staging bs
LEFT JOIN 
    Reporting_area ra
ON 
    bs.reporting_area = ra.code
WHERE 
    ra.ra_id IS NULL;

--Replace null valuew with empty strings for district column--
UPDATE BOSTON_STAGING SET reporting_area = '' where reporting_area IS NULL;

--Upload IDs--
UPDATE Boston_staging
SET rep_area_id = ra.ra_id
FROM Reporting_area ra
WHERE 
    Boston_staging.reporting_area = ra.code;

--migrating data from stage to fact table--
INSERT INTO Boston_Crime (
    Crime_Type_id,
    Date_id,
    LOC_ID,
    RA_ID,
    CRIME_ID,
    Incident_Number,
    Crime_Count,
    Shooting
)
SELECT
    bs.CRIME_TYPE_ID,
    bs.DATE_ID,
    bs.LOC_ID,
    bs.REP_AREA_ID,
    bs._id, -- Assuming _id is used as the CRIME_ID
    bs.INCIDENT_NUMBER,
    1 AS Crime_Count, -- Assuming each row represents one crime occurrence
    bs.SHOOTING
FROM
    BOSTON_STAGING bs;

SELECT* FROM BOSTON_CRIME;


