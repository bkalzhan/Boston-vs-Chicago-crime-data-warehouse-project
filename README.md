# Boston vs Chicago Crime Comparison Data Warehouse  

### Project Overview  
This project was completed as part of the **MET CS 689: Designing and Implementing a Data Warehouse** course during my Master's program. The primary objective was to design and implement a data warehouse for comparing crime data between Boston and Chicago using public records.  

### Data Sources  
The crime data for both Boston and Chicago was provided as large spreadsheets (structured as flat tables) sourced from public records. 
1)	https://data.boston.gov/dataset/crime-incident-reports-august-2015-to-date-source-new-system/resource/b973d8cb-eeb2-4e7e-99da-c92938efc9c0
2)	https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-Present/ijzp-q8t2/data_preview 

### Objectives  
- Design a data warehouse schema to enable comprehensive analytics on crime data for both cities.  
- Facilitate separate and comparative analyses using optimized fact and dimension tables.  
- Precompute key metrics for immediate analysis with minimal query complexity.  

---

### Data Warehouse Design  

The design includes:  

#### Dimension Tables  
1. **Main Dimensions:**  
   - **Crime Dimension:** Information about crime types and categories.  
   - **Location Dimension:** Includes details about neighborhoods, districts, and cities.  
   - **Victim Dimension:** Demographics and victim-related data.  
   - **Offender Dimension:** Information about offenders where applicable.  

2. **Time Dimensions:**  
   - Time (hour-level granularity)  
   - Day  
   - Date  
   - Month  

#### Fact Tables  
1. **City-Specific Fact Tables:**  
   - **Boston Crime Fact Table**: Stores crime data specific to Boston.  
   - **Chicago Crime Fact Table**: Stores crime data specific to Chicago.  

2. **Common Fact Table:**  
   - Combines data from both cities for comparative analysis of trends, patterns, and statistics.  

3. **Precomputed Analytics Tables:**  
   - **Weekly Analysis Table:** Aggregated weekly crime metrics for rapid insights.  
   - **Hourly Analysis Table:** Hourly crime metrics with precomputed values for easy querying.  

---

### ETL Process  

The ETL process was implemented using **Python (pandas library)** for extraction and initial transformation, and **SQL scripts** for subsequent transformation and loading into the data warehouse.  

#### Steps:  
1. **Data Extraction (Python):**  
   - Imported the spreadsheets and checked for data quality issues such as missing values, inconsistent formats, and duplicate records.  

2. **Pre-Transformation (Python):**  
   - Performed initial data cleaning and standardization.  

3. **Transformation & Loading (SQL):**  
   - Created and populated dimension and fact tables.  
   - Implemented various transformations such as:  
     - Deriving time-related attributes for time dimensions.  
     - Aggregating data for precomputed tables.  

---

### Features and Benefits  
- **Separate Analytics:** Separate fact tables for Boston and Chicago enable focused city-specific analysis.  
- **Comparative Analysis:** A common fact table facilitates comparative studies between the two cities.  
- **Precomputed Tables:** Simplified queries for weekly and hourly analyses, enabling fast and efficient insights.  
- **Optimized Design:** Dimensions and time grains ensure flexibility and depth in analytics.  

---

### How to Use  
1. **Code Repository:**  
   - All Python scripts for the extraction and pre-transformation processes are included.  
   - SQL scripts for transformations and data loading are also provided.  

2. **Execution Steps:**  
   - Run Python scripts to extract and preprocess the data.  
   - Execute SQL scripts to load and transform data into the data warehouse.  

---

### Technologies Used  
- **Python:** pandas for data extraction and preprocessing.  
- **SQL:** For data transformations and warehouse loading.  
- **Database Management System:** PostgreSQL. 

---

### Future Improvements  
- Enhance the data model by adding more granular dimensions.  
- Integrate additional public data sources for a more comprehensive analysis.  
- Implement a dashboard for interactive visualization of crime trends and comparisons.  
