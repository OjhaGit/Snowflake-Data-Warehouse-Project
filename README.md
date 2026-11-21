# Snowflake-Data-Warehouse-Project
Building a modern data warehoise with Snowflake, including ETL processes, data modelling and analytics.

Bronze Layer – Raw Data Ingestion
The Bronze Layer serves as the raw data landing zone of the Snowflake Data Warehouse, ingesting source datasets from CRM and ERP systems.

Key Implementations:

Created dedicated Bronze tables to store raw CRM and ERP datasets.
Configured CSV file formats to handle delimiters, headers, NULL values, and data parsing.
Created separate Snowflake internal stages for CRM and ERP source files.
Implemented bulk data ingestion using the COPY INTO command.
Developed a SQL stored procedure to automate the loading of all six source tables.
Implemented full refresh loading using TRUNCATE TABLE and FORCE = TRUE.
Added exception handling and batch execution-duration tracking.
Performed initial data validation after ingestion.
Outcome: Successfully established a centralized raw data layer to store source data before downstream cleansing and transformation in the Silver Layer.

--====================================================================================================================================================

Silver Layer – Data Cleansing and Transformation
The Silver Layer processes raw data from the Bronze Layer and converts it into clean, standardized, and reliable datasets for downstream analytical processing.

Key Implementations:

Created six structured Silver tables for CRM and ERP datasets.
Implemented customer deduplication using ROW_NUMBER() window functions.
Standardized customer names, gender, marital status, product lines, and country information.
Applied NULL handling using COALESCE() and NULLIF().
Converted integer-based date values into proper DATE formats using TRY_TO_DATE().
Derived product category IDs and standardized product keys using string functions.
Calculated product effective end dates using the LEAD() window function.
Implemented sales amount and price validation using business rules.
Validated customer IDs and birth dates.
Developed a SQL stored procedure to automate all six Bronze-to-Silver transformations.
Implemented execution-duration tracking and exception handling.
Outcome: Established a standardized and cleansed data layer that prepares reliable datasets for business-level transformations in the Gold Layer.

--========================================================================================================================================================

Gold Layer – Dimensional Modelling and Business Analytics
The Gold Layer provides business-ready analytical datasets by integrating the cleansed CRM and ERP data from the Silver Layer.

Key Implementations:

Created a customer dimension (DIM_CUSTOMERS) by integrating CRM customer information with ERP demographic and location data.
Created a product dimension (DIM_PRODUCTS) by combining CRM product details with ERP category information.
Generated surrogate keys for customer and product dimensions using ROW_NUMBER().
Applied business rules to prioritize CRM gender information and use ERP gender as a fallback.
Filtered active product records based on product end dates.
Created a sales fact view (FACT_SALES) containing transactional measures and dimension surrogate keys.
Established logical relationships between fact and dimension views using LEFT JOINs.
Implemented a Star Schema to support analytical reporting and business intelligence.
Outcome: Developed a business-ready analytical layer that enables customer, product, and sales analysis through dimensional modelling.
