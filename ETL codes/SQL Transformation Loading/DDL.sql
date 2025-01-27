----------------------------DDL: Creating Tables----------------------------

--------------DDL: Creating dimensional tables--------------
CREATE TABLE Location (
    Loc_id SERIAL PRIMARY KEY,
    District VARCHAR(50),
    Ward INT,
    Community_area INT,
    Street VARCHAR(100)
);

CREATE TABLE Crime_Type (
    Crime_type_id SERIAL PRIMARY KEY,
    Crime_code VARCHAR(10) NOT NULL,
    Crime_description VARCHAR(255) NOT NULL,
    Effective_date DATE NOT NULL,
    Expiration_date DATE,
    Status VARCHAR(20) CHECK (Status IN ('Current', 'Expired'))
);

CREATE TABLE Reporting_Area (
    RA_ID SERIAL PRIMARY KEY,
    Code VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE City (
    City_id SERIAL PRIMARY KEY,
	Original_ID INT;
    Current_name VARCHAR(100) NOT NULL,
    "2025_City_name" VARCHAR(100),
    "2024_City_name" VARCHAR(100)
);

CREATE TABLE Date (
    Date_id SERIAL PRIMARY KEY,
    Year INT NOT NULL,
    Month INT NOT NULL CHECK (Month BETWEEN 1 AND 12),
    Day INT NOT NULL CHECK (Day BETWEEN 1 AND 31)
);

CREATE TABLE Month (
    Month_id SERIAL PRIMARY KEY,
    Year INT NOT NULL,
    Month INT NOT NULL CHECK (Month BETWEEN 1 AND 12)
);


CREATE TABLE Day (
    Day_id SERIAL PRIMARY KEY,
    Day_of_week VARCHAR(10) NOT NULL
);

INSERT INTO Day(Day_of_week) VALUES('Monday');
INSERT INTO Day(Day_of_week) VALUES('Tuesday');
INSERT INTO Day(Day_of_week) VALUES('Wednesday');
INSERT INTO Day(Day_of_week) VALUES('Thursday');
INSERT INTO Day(Day_of_week) VALUES('Friday');
INSERT INTO Day(Day_of_week) VALUES('Saturday');
INSERT INTO Day(Day_of_week) VALUES('Sunday');

CREATE TABLE Time (
    Time_id SERIAL PRIMARY KEY,
    Hour INT NOT NULL CHECK (Hour BETWEEN 0 AND 23)
);


--DDL: Creating fact tables
CREATE TABLE Chicago_Crime (
    Crime_Type_id INT NOT NULL,
    Date_id INT NOT NULL,
    Updated_on INT NOT NULL,
    LOC_ID INT NOT NULL,
    CRIME_ID INT,
    Case_Number VARCHAR(50),
    Crime_Count INT,
    Arrest INT,
    Domestic INT,
	Location_description VARCHAR(255);
    PRIMARY KEY (Crime_Type_id, Date_id, Updated_on, LOC_ID),
    FOREIGN KEY (Crime_Type_id) REFERENCES Crime_Type(Crime_Type_id),
    FOREIGN KEY (Date_id) REFERENCES Date(Date_id),
    FOREIGN KEY (Updated_on) REFERENCES Date(Date_id),
    FOREIGN KEY (LOC_ID) REFERENCES Location(LOC_ID)
);

CREATE TABLE Boston_Crime (
    Boston_Crime_id SERIAL PRIMARY KEY,
    Crime_Type_id INT NOT NULL,
    Date_id INT NOT NULL,
    LOC_ID INT NOT NULL,
    RA_ID INT NOT NULL,
    CRIME_ID INT,
    Incident_Number VARCHAR(50),
    Crime_Count INT,
    Shooting INT,
    FOREIGN KEY (Crime_Type_id) REFERENCES Crime_Type(Crime_Type_id),
    FOREIGN KEY (Date_id) REFERENCES Date(Date_id),
    FOREIGN KEY (LOC_ID) REFERENCES Location(LOC_ID),
    FOREIGN KEY (RA_ID) REFERENCES Reporting_Area(RA_ID)
);

CREATE TABLE Common_Crime (
    Crime_Type_id INT NOT NULL,
    Date_id INT NOT NULL,
    LOC_ID INT NOT NULL,
    City_Id INT NOT NULL,
    Total_Crime_Count INT,
    Crime_Type_Count INT,
    City_Crime_Ratio DECIMAL(10, 5),
    Crime_Frequency DECIMAL(10, 5),
    PRIMARY KEY (Crime_Type_id, Date_id, LOC_ID, City_Id),
    FOREIGN KEY (Crime_Type_id) REFERENCES Crime_Type(Crime_Type_id),
    FOREIGN KEY (Date_id) REFERENCES Date(Date_id),
    FOREIGN KEY (LOC_ID) REFERENCES Location(LOC_ID),
    FOREIGN KEY (City_Id) REFERENCES City(City_Id)
);

ALTER TABLE Common_Crime
ADD COLUMN Month_id INT;

UPDATE Common_Crime cc
SET Month_id = (
    SELECT m.Month_id
    FROM Date d
    JOIN Month m
    ON d.Year = m.Year AND d.Month = m.Month
    WHERE d.Date_id = cc.Date_id
);

ALTER TABLE Common_Crime
DROP COLUMN Date_id;

ALTER TABLE Common_Crime
ADD CONSTRAINT fk_month_id
FOREIGN KEY (Month_id) REFERENCES Month(Month_id);

SELECT * FROM Common_Crime;
SELECT * FROM Month;

CREATE TABLE Day_of_Week_Crime (
    ID SERIAL PRIMARY KEY, -- Unique identifier
    City_id INT NOT NULL, -- Foreign key to City table
    Day_id INT NOT NULL, -- Foreign key to Day table
    Avg_crimes_per_day DECIMAL(10, 2), -- Average crimes per day
    Crime_total_count_per_day INT, -- Total crimes per day
    Most_common_crime_Type INT, -- Foreign key to Crime_Type table
    Most_common_crime_count INT, -- Count of the most common crime type
    Most_common_crime_percentage DECIMAL(10, 5), -- (Most_common_crime_count / Crime_total_count_per_day)
    FOREIGN KEY (City_id) REFERENCES City(City_id),
    FOREIGN KEY (Day_id) REFERENCES Day(Day_id),
    FOREIGN KEY (Most_common_crime_Type) REFERENCES Crime_Type(Crime_Type_id)
);

CREATE TABLE Hour_of_Day_Crime (
    ID SERIAL PRIMARY KEY,
    City_Id INT NOT NULL,
    Time_id INT NOT NULL,
	Total_Crime_Count INT,
    Avg_Crimes_Per_Hour DECIMAL(10, 5),
    Most_Common_Crime INT NOT NULL,
	Most_Crime_Type_Count INT,
    Common_Crime_Percentage DECIMAL(10, 5),
    FOREIGN KEY (Most_Common_Crime) REFERENCES Crime_Type(Crime_Type_id),
    FOREIGN KEY (City_Id) REFERENCES City(City_Id),
    FOREIGN KEY (Time_id) REFERENCES Time(Time_id)
);