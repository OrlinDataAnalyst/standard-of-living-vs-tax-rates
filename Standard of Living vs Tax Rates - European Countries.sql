/*
    
    PROJECT: Relation between Standard of Living and Tax Rates in European countries (based on Eurostat datasets)

    Datasets:
        1. Price Level Indices
        2. GDP per capita in PPS 
        3. Tax Rates

    Skills used: Data cleaning, Converting Data Types, Creating Views, Joins, Unpivot, Nested queries, Aggregate funcions, CTE, Case

*/

USE TaxLifeIndex;
GO

-- STEP 1: CLEAN DATA IN EACH TABLE

EXEC sp_rename 'PriceLevelIndices.[TIME]', 'Country', 'COLUMN';
EXEC sp_rename 'GDPPercapitaPPS.[TIME]', 'Country', 'COLUMN';
EXEC sp_rename 'TaxRates.[TIME]', 'Country', 'COLUMN';

UPDATE PriceLevelIndices SET Country = 'Czech Republic' WHERE Country = 'Czechia';
UPDATE GDPPercapitaPPS SET Country = 'Czech Republic' WHERE Country = 'Czechia';
UPDATE TaxRates SET Country = 'Czech Republic' WHERE Country = 'Czechia';

DELETE FROM PriceLevelIndices
WHERE Country IN ('European Union - 27 countries (from 2020)', 'Euro area – 20 countries (from 2023)',
                  'Euro area - 19 countries  (2015-2022)', 'United Kingdom', 'Bosnia and Herzegovina',
                  'Montenegro', 'North Macedonia', 'Albania', 'Serbia', 'Liechtenstein', 'Kosovo*',
                  'Türkiye', 'United States', 'Japan', '')

DELETE FROM GDPPercapitaPPS
WHERE Country IN ('United Kingdom', 'Bosnia and Herzegovina', 'Montenegro', 'North Macedonia',
                  'Albania', 'Serbia','Liechtenstein', 'Türkiye', 'United States', 'Japan', '')
                  
DELETE FROM TaxRates
WHERE Country IN ('European Union - 27 countries (from 2020)', 'European Union - 28 countries (2013-2020)',
                  'European Union - 15 countries (1995-2004)', 'Euro area – 20 countries (from 2023)',
                  'Euro area - 19 countries  (2015-2022)', 'Türkiye', 'United States', 'United Kingdom', 'Japan', '')


-- STEP 2: UNPIVOT EACH TABLE INTO LONG FORMAT / CREATE VIEWS


-- Create View for PriceLevelIndices and unpivot

DROP VIEW IF EXISTS v_PriceLevelIndices;
GO
CREATE VIEW v_PriceLevelIndices AS
SELECT 
    Country,
    Year,
    MAX(PriceIndex) AS PriceIndex       -- remove Eurostat duplicates        
FROM (
    SELECT 
        TRIM(Country) AS Country,
        CAST(Year AS INT) AS Year,
        TRY_CAST(LTRIM(RTRIM(Value)) AS DECIMAL(6,1)) AS PriceIndex
    FROM (
        SELECT Country, [2020],[2021],[2022],[2023],[2024]
        FROM PriceLevelIndices
    ) src
    UNPIVOT (Value FOR Year IN ([2020],[2021],[2022],[2023],[2024])) AS unpvt
    WHERE TRY_CAST(LTRIM(RTRIM(Value)) AS DECIMAL(6,2)) IS NOT NULL
) t
GROUP BY Country, Year;                                                         
GO


-- Create View for GDPPercapitaPPS and unpivot

DROP VIEW IF EXISTS v_GDPPercapitaPPS;
GO
CREATE VIEW v_GDPPercapitaPPS AS
SELECT 
    Country,
    Year,
    MAX(GDP_PerCapita_PPS) AS GDP_PerCapita_PPS
FROM (
    SELECT 
        TRIM(Country) AS Country,
        CAST(Year AS INT) AS Year,
        TRY_CAST(LTRIM(RTRIM(Value)) AS DECIMAL(6,0)) AS GDP_PerCapita_PPS      -- convert Eurostat text values to a clean number
    FROM (
        SELECT Country, [2020],[2021],[2022],[2023],[2024]
        FROM GDPPercapitaPPS
    ) src
    UNPIVOT (Value FOR Year IN ([2020],[2021],[2022],[2023],[2024])) AS unpvt
    WHERE TRY_CAST(LTRIM(RTRIM(Value)) AS DECIMAL(6,2)) IS NOT NULL
) t
GROUP BY Country, Year;
GO


-- Create View for TaxRates and unpivot

DROP VIEW IF EXISTS v_TaxRates;
GO
CREATE VIEW v_TaxRates AS
SELECT 
    Country,
    Year,
    MAX(TaxRate) AS TaxRate         
FROM (
    SELECT 
        TRIM(Country) AS Country,
        CAST(Year AS INT) AS Year,
        TRY_CAST(LTRIM(RTRIM(Value)) AS DECIMAL(5,2)) AS TaxRate
    FROM (
        SELECT Country, [2020],[2021],[2022],[2023],[2024]
        FROM TaxRates
    ) src
    UNPIVOT (Value FOR Year IN ([2020],[2021],[2022],[2023],[2024])) AS unpvt
    WHERE TRY_CAST(LTRIM(RTRIM(Value)) AS DECIMAL(5,2)) IS NOT NULL
) t
GROUP BY Country, Year;
GO


-- STEP 3: CREATE FINAL ANALYSIS VIEW

DROP VIEW IF EXISTS v_Europe_Economic_Dashboard;
GO
CREATE VIEW v_Europe_Economic_Dashboard AS
WITH data AS (                                                      -- using CTE to create a clean, complete dataset
    SELECT
        COALESCE(p.Country, g.Country, t.Country) AS Country,       -- makes sure no row gets lost (Country)
        COALESCE(p.Year, g.Year, t.Year) AS Year,
        p.PriceIndex,
        g.GDP_PerCapita_PPS,
        t.TaxRate
    FROM v_PriceLevelIndices AS p
    FULL OUTER JOIN v_GDPPercapitaPPS AS g ON p.Country = g.Country AND p.Year = g.Year
    FULL OUTER JOIN v_TaxRates        AS t ON p.Country = t.Country AND p.Year = t.Year
)
SELECT
    Country,
    Year,
    PriceIndex,
    GDP_PerCapita_PPS AS GDP_PerCapita_PPS_Index,                   -- index where the EU-27 average = 100

/* 

    Adjusts GDP for cost of living or how many baskets of goods you can buy (Real_Purchasing_Power_Index)
    (*100 -> Turns the ratio into an index where 100 = EU average)

*/

    CAST(ROUND(GDP_PerCapita_PPS / NULLIF(PriceIndex,0) * 100.0, 1) AS DECIMAL(10,1)) AS PurchasingPower_Index,    
    ROUND(CAST(TaxRate AS DECIMAL(6,1)), 1) AS TaxRate_pct,
    
    -- Fix the wrong and misleading numbers when tax data is missing

    CASE                                                                                                               
        WHEN TaxRate IS NOT NULL THEN
            CAST(ROUND((GDP_PerCapita_PPS / NULLIF(PriceIndex,0) * 100.0) 
                       * (1 - TaxRate/100.0), 1) AS DECIMAL(6,1))
        ELSE NULL 
    END AS AfterTax_PurchasingPower,

    RANK() OVER (PARTITION BY Year 
                 ORDER BY (GDP_PerCapita_PPS / NULLIF(PriceIndex,0) * 100.0) DESC)
        AS Rank_PurchasingPower,

    RANK() OVER (PARTITION BY Year ORDER BY TaxRate ASC)
        AS Rank_Lowest_TaxWedge

FROM data
WHERE GDP_PerCapita_PPS IS NOT NULL
  AND PriceIndex IS NOT NULL;
GO

SELECT * FROM v_Europe_Economic_Dashboard
EXEC sp_refreshview 'v_Europe_Economic_Dashboard';
GO

/*

    1. Do higher taxes reduce after-tax purchasing power? Compare tax rate to real purchasing power after tax.

*/

SELECT Country, Year,
       TaxRate_pct,
       AfterTax_PurchasingPower
FROM v_Europe_Economic_Dashboard
ORDER BY TaxRate_pct;

/*

    2. Does income (GDP per capita) compensate for higher tax wedge?
       Identify wealthy countries with high taxes (typical Nordic model) vs poor countries with high tax burden.

*/

SELECT Country, Year,
       GDP_PerCapita_PPS_Index,
       TaxRate_pct
FROM v_Europe_Economic_Dashboard
ORDER BY GDP_PerCapita_PPS_Index DESC;

/*

    3. Is standard of living driven by prices or taxes? 
       Find whether high prices or high taxes have more impact on purchasing power.

*/

SELECT Country, Year,
       PriceIndex,
       PurchasingPower_Index,
       TaxRate_pct
FROM v_Europe_Economic_Dashboard
ORDER BY PriceIndex DESC;

/*

    4. Tax Efficiency Score measures how much purchasing power remains after tax.

*/

SELECT Country, Year,
       PurchasingPower_Index,
       AfterTax_PurchasingPower,
       AfterTax_PurchasingPower / NULLIF(TaxRate_pct, 0) AS TaxEfficiency
FROM v_Europe_Economic_Dashboard
ORDER BY TaxEfficiency DESC

/*

    5. Compare spending power across countries. If someone from Country A earns their income and
       spends it in Country B, how much purchasing power would they have compared to spending at home?

*/

SELECT 
    A.Country AS EarnerCountry,
    B.Country AS DestinationCountry,
    A.Year,
    A.AfterTax_PurchasingPower,
    B.PriceIndex,
    CAST(A.AfterTax_PurchasingPower / NULLIF(B.PriceIndex, 0) AS DECIMAL(10,1)) AS Real_Power_Abroad,
    -- show % change vs staying home
    CAST(
        (A.AfterTax_PurchasingPower / NULLIF(B.PriceIndex, 0)) 
        / (A.AfterTax_PurchasingPower / NULLIF(A.PriceIndex, 0)) * 100.0 
        AS DECIMAL(6,1)
    ) AS Pct_Of_Home_Power
FROM v_Europe_Economic_Dashboard A
CROSS JOIN v_PriceLevelIndices B
WHERE A.Year = B.Year
  AND A.Year = 2024;


