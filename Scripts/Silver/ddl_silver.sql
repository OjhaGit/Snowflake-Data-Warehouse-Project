USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE DATAWAREHOUSE;
USE SCHEMA SILVER;


-- ============================================================
-- 1. CRM CUSTOMER INFO
-- ============================================================

DROP TABLE IF EXISTS SILVER.CRM_CUST_INFO;

CREATE TABLE SILVER.CRM_CUST_INFO (
    CST_ID              INT,
    CST_KEY             VARCHAR(50),
    CST_FIRSTNAME       VARCHAR(50),
    CST_LASTNAME        VARCHAR(50),
    CST_MARITAL_STATUS  VARCHAR(50),
    CST_GNDR            VARCHAR(50),
    CST_CREATE_DATE     DATE,
    DWH_CREATE_DATE     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================
-- 2. CRM PRODUCT INFO
-- ============================================================

DROP TABLE IF EXISTS SILVER.CRM_PRD_INFO;

CREATE TABLE SILVER.CRM_PRD_INFO (
    PRD_ID          INT,
    CAT_ID          VARCHAR(50),
    PRD_KEY         VARCHAR(50),
    PRD_NM          VARCHAR(50),
    PRD_COST        INT,
    PRD_LINE        VARCHAR(50),
    PRD_START_DT    DATE,
    PRD_END_DT      DATE,
    DWH_CREATE_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================
-- 3. CRM SALES DETAILS
-- ============================================================

DROP TABLE IF EXISTS SILVER.CRM_SALES_DETAILS;

CREATE TABLE SILVER.CRM_SALES_DETAILS (
    SLS_ORD_NUM     VARCHAR(50),
    SLS_PRD_KEY     VARCHAR(50),
    SLS_CUST_ID     INT,
    SLS_ORDER_DT    DATE,
    SLS_SHIP_DT     DATE,
    SLS_DUE_DT      DATE,
    SLS_SALES       INT,
    SLS_QUANTITY    INT,
    SLS_PRICE       INT,
    DWH_CREATE_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================
-- 4. ERP LOCATION
-- ============================================================

DROP TABLE IF EXISTS SILVER.ERP_LOC_A101;

CREATE TABLE SILVER.ERP_LOC_A101 (
    CID             VARCHAR(50),
    CNTRY           VARCHAR(50),
    DWH_CREATE_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================
-- 5. ERP CUSTOMER
-- ============================================================

DROP TABLE IF EXISTS SILVER.ERP_CUST_AZ12;

CREATE TABLE SILVER.ERP_CUST_AZ12 (
    CID             VARCHAR(50),
    BDATE           DATE,
    GEN             VARCHAR(50),
    DWH_CREATE_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================
-- 6. ERP PRODUCT CATEGORY
-- ============================================================

DROP TABLE IF EXISTS SILVER.ERP_PX_CAT_G1V2;

CREATE TABLE SILVER.ERP_PX_CAT_G1V2 (
    ID              VARCHAR(50),
    CAT             VARCHAR(50),
    SUBCAT          VARCHAR(50),
    MAINTENANCE     VARCHAR(50),
    DWH_CREATE_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
