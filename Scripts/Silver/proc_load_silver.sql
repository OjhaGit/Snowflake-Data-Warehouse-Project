-- ============================================================
-- SILVER LAYER: BRONZE TO SILVER ETL STORED PROCEDURE
-- ============================================================

CREATE OR REPLACE PROCEDURE DATAWAREHOUSE.SILVER.LOAD_SILVER()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$

DECLARE
    START_TIME        TIMESTAMP_NTZ;
    END_TIME          TIMESTAMP_NTZ;
    BATCH_START_TIME  TIMESTAMP_NTZ;
    BATCH_END_TIME    TIMESTAMP_NTZ;

    CRM_CUST_DURATION  NUMBER;
    CRM_PRD_DURATION   NUMBER;
    CRM_SALES_DURATION NUMBER;
    ERP_CUST_DURATION  NUMBER;
    ERP_LOC_DURATION   NUMBER;
    ERP_CAT_DURATION   NUMBER;

BEGIN

    BATCH_START_TIME := CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;

    -- =====================================================
    -- LOADING CRM TABLES
    -- =====================================================

    -- 1. CRM CUSTOMER INFO
    START_TIME := CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;

    TRUNCATE TABLE DATAWAREHOUSE.SILVER.CRM_CUST_INFO;

    INSERT INTO DATAWAREHOUSE.SILVER.CRM_CUST_INFO
    (
        CST_ID,
        CST_KEY,
        CST_FIRSTNAME,
        CST_LASTNAME,
        CST_MARITAL_STATUS,
        CST_GNDR,
        CST_CREATE_DATE
    )
    SELECT
        CST_ID,
        CST_KEY,
        TRIM(CST_FIRSTNAME) AS CST_FIRSTNAME,
        TRIM(CST_LASTNAME) AS CST_LASTNAME,

        CASE
            WHEN UPPER(TRIM(CST_MARITAL_STATUS)) = 'S'
                THEN 'Single'
            WHEN UPPER(TRIM(CST_MARITAL_STATUS)) = 'M'
                THEN 'Married'
            ELSE 'n/a'
        END AS CST_MARITAL_STATUS,

        CASE
            WHEN UPPER(TRIM(CST_GNDR)) = 'F'
                THEN 'Female'
            WHEN UPPER(TRIM(CST_GNDR)) = 'M'
                THEN 'Male'
            ELSE 'n/a'
        END AS CST_GNDR,

        CST_CREATE_DATE

    FROM
    (
        SELECT
            *,
            ROW_NUMBER() OVER
            (
                PARTITION BY CST_ID
                ORDER BY CST_CREATE_DATE DESC
            ) AS FLAG_LAST

        FROM DATAWAREHOUSE.BRONZE.CRM_CUST_INFO
        WHERE CST_ID IS NOT NULL

    ) T
    WHERE FLAG_LAST = 1;

    END_TIME := CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;
    CRM_CUST_DURATION := DATEDIFF(SECOND, START_TIME, END_TIME);


    -- 2. CRM PRODUCT INFO
    START_TIME := CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;

    TRUNCATE TABLE DATAWAREHOUSE.SILVER.CRM_PRD_INFO;

    INSERT INTO DATAWAREHOUSE.SILVER.CRM_PRD_INFO
    (
        PRD_ID,
        CAT_ID,
        PRD_KEY,
        PRD_NM,
        PRD_COST,
        PRD_LINE,
        PRD_START_DT,
        PRD_END_DT
    )
    SELECT
        PRD_ID,

        REPLACE(SUBSTR(PRD_KEY, 1, 5), '-', '_') AS CAT_ID,

        SUBSTR(PRD_KEY, 7) AS PRD_KEY,

        PRD_NM,

        COALESCE(PRD_COST, 0) AS PRD_COST,

        CASE
            WHEN UPPER(TRIM(PRD_LINE)) = 'M'
                THEN 'Mountain'
            WHEN UPPER(TRIM(PRD_LINE)) = 'R'
                THEN 'Road'
            WHEN UPPER(TRIM(PRD_LINE)) = 'S'
                THEN 'Other Sales'
            WHEN UPPER(TRIM(PRD_LINE)) = 'T'
                THEN 'Touring'
            ELSE 'n/a'
        END AS PRD_LINE,

        CAST(PRD_START_DT AS DATE) AS PRD_START_DT,

        CAST(
            DATEADD(
                DAY,
                -1,
                LEAD(PRD_START_DT) OVER
                (
                    PARTITION BY PRD_KEY
                    ORDER BY PRD_START_DT
                )
            ) AS DATE
        ) AS PRD_END_DT

    FROM DATAWAREHOUSE.BRONZE.CRM_PRD_INFO;

    END_TIME := CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;
    CRM_PRD_DURATION := DATEDIFF(SECOND, START_TIME, END_TIME);


    -- 3. CRM SALES DETAILS
    START_TIME := CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;

    TRUNCATE TABLE DATAWAREHOUSE.SILVER.CRM_SALES_DETAILS;

    INSERT INTO DATAWAREHOUSE.SILVER.CRM_SALES_DETAILS
    (
        SLS_ORD_NUM,
        SLS_PRD_KEY,
        SLS_CUST_ID,
        SLS_ORDER_DT,
        SLS_SHIP_DT,
        SLS_DUE_DT,
        SLS_SALES,
        SLS_QUANTITY,
        SLS_PRICE
    )
    SELECT
        SLS_ORD_NUM,
        SLS_PRD_KEY,
        SLS_CUST_ID,

        CASE
            WHEN SLS_ORDER_DT = 0
              OR LENGTH(TO_VARCHAR(SLS_ORDER_DT)) <> 8
                THEN NULL
            ELSE TRY_TO_DATE(TO_VARCHAR(SLS_ORDER_DT), 'YYYYMMDD')
        END AS SLS_ORDER_DT,

        CASE
            WHEN SLS_SHIP_DT = 0
              OR LENGTH(TO_VARCHAR(SLS_SHIP_DT)) <> 8
                THEN NULL
            ELSE TRY_TO_DATE(TO_VARCHAR(SLS_SHIP_DT), 'YYYYMMDD')
        END AS SLS_SHIP_DT,

        CASE
            WHEN SLS_DUE_DT = 0
              OR LENGTH(TO_VARCHAR(SLS_DUE_DT)) <> 8
                THEN NULL
            ELSE TRY_TO_DATE(TO_VARCHAR(SLS_DUE_DT), 'YYYYMMDD')
        END AS SLS_DUE_DT,

        CASE
            WHEN SLS_SALES IS NULL
              OR SLS_SALES <= 0
              OR SLS_SALES <> SLS_QUANTITY * ABS(SLS_PRICE)
                THEN SLS_QUANTITY * ABS(SLS_PRICE)
            ELSE SLS_SALES
        END AS SLS_SALES,

        SLS_QUANTITY,

        CASE
            WHEN SLS_PRICE IS NULL OR SLS_PRICE <= 0
                THEN CAST(
                    TRUNC(SLS_SALES / NULLIF(SLS_QUANTITY, 0))
                    AS INT
                )
            ELSE SLS_PRICE
        END AS SLS_PRICE

    FROM DATAWAREHOUSE.BRONZE.CRM_SALES_DETAILS;

    END_TIME := CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;
    CRM_SALES_DURATION := DATEDIFF(SECOND, START_TIME, END_TIME);


    -- =====================================================
    -- LOADING ERP TABLES
    -- =====================================================

    -- 4. ERP CUSTOMER
    START_TIME := CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;

    TRUNCATE TABLE DATAWAREHOUSE.SILVER.ERP_CUST_AZ12;

    INSERT INTO DATAWAREHOUSE.SILVER.ERP_CUST_AZ12
    (
        CID,
        BDATE,
        GEN
    )
    SELECT
        CASE
            WHEN CID LIKE 'NAS%'
                THEN SUBSTR(CID, 4)
            ELSE CID
        END AS CID,

        CASE
            WHEN BDATE > CURRENT_DATE()
                THEN NULL
            ELSE BDATE
        END AS BDATE,

        CASE
            WHEN UPPER(TRIM(GEN)) IN ('F', 'FEMALE')
                THEN 'Female'
            WHEN UPPER(TRIM(GEN)) IN ('M', 'MALE')
                THEN 'Male'
            ELSE 'n/a'
        END AS GEN

    FROM DATAWAREHOUSE.BRONZE.ERP_CUST_AZ12;

    END_TIME := CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;
    ERP_CUST_DURATION := DATEDIFF(SECOND, START_TIME, END_TIME);


    -- 5. ERP LOCATION
    START_TIME := CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;

    TRUNCATE TABLE DATAWAREHOUSE.SILVER.ERP_LOC_A101;

    INSERT INTO DATAWAREHOUSE.SILVER.ERP_LOC_A101
    (
        CID,
        CNTRY
    )
    SELECT
        REPLACE(CID, '-', '') AS CID,

        CASE
            WHEN TRIM(CNTRY) = 'DE'
                THEN 'Germany'
            WHEN TRIM(CNTRY) IN ('US', 'USA')
                THEN 'United States'
            WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL
                THEN 'n/a'
            ELSE TRIM(CNTRY)
        END AS CNTRY

    FROM DATAWAREHOUSE.BRONZE.ERP_LOC_A101;

    END_TIME := CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;
    ERP_LOC_DURATION := DATEDIFF(SECOND, START_TIME, END_TIME);


    -- 6. ERP PRODUCT CATEGORY
    START_TIME := CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;

    TRUNCATE TABLE DATAWAREHOUSE.SILVER.ERP_PX_CAT_G1V2;

    INSERT INTO DATAWAREHOUSE.SILVER.ERP_PX_CAT_G1V2
    (
        ID,
        CAT,
        SUBCAT,
        MAINTENANCE
    )
    SELECT
        ID,
        CAT,
        SUBCAT,
        MAINTENANCE

    FROM DATAWAREHOUSE.BRONZE.ERP_PX_CAT_G1V2;

    END_TIME := CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;
    ERP_CAT_DURATION := DATEDIFF(SECOND, START_TIME, END_TIME);


    -- =====================================================
    -- BATCH COMPLETION
    -- =====================================================

    BATCH_END_TIME := CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;

    RETURN
        '========================================='
        || CHAR(10) || 'SILVER LAYER LOADING COMPLETED'
        || CHAR(10) || 'CRM CUSTOMER: ' || CRM_CUST_DURATION || ' seconds'
        || CHAR(10) || 'CRM PRODUCT: ' || CRM_PRD_DURATION || ' seconds'
        || CHAR(10) || 'CRM SALES: ' || CRM_SALES_DURATION || ' seconds'
        || CHAR(10) || 'ERP CUSTOMER: ' || ERP_CUST_DURATION || ' seconds'
        || CHAR(10) || 'ERP LOCATION: ' || ERP_LOC_DURATION || ' seconds'
        || CHAR(10) || 'ERP CATEGORY: ' || ERP_CAT_DURATION || ' seconds'
        || CHAR(10) || 'TOTAL DURATION: '
        || DATEDIFF(SECOND, BATCH_START_TIME, BATCH_END_TIME)
        || ' seconds'
        || CHAR(10) || '=========================================';


EXCEPTION
    WHEN OTHER THEN

        RETURN
            '========================================='
            || CHAR(10) || 'ERROR OCCURRED DURING SILVER LOADING'
            || CHAR(10) || 'ERROR CODE: ' || SQLCODE
            || CHAR(10) || 'ERROR MESSAGE: ' || SQLERRM
            || CHAR(10) || 'SQL STATE: ' || SQLSTATE
            || CHAR(10) || '=========================================';

END;
$$;

CALL DATAWAREHOUSE.SILVER.LOAD_SILVER();

SELECT * FROM DATAWAREHOUSE.SILVER.CRM_CUST_INFO;
SELECT * FROM DATAWAREHOUSE.SILVER.CRM_PRD_INFO;
SELECT * FROM DATAWAREHOUSE.SILVER.CRM_SALES_DETAILS;
SELECT * FROM DATAWAREHOUSE.SILVER.ERP_CUST_AZ12;
SELECT * FROM DATAWAREHOUSE.SILVER.ERP_LOC_A101;
SELECT * FROM DATAWAREHOUSE.SILVER.ERP_PX_CAT_G1V2;
