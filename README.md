# Standard of Living vs Tax Rates in European Countries (2020–2024)  
**Analyzing the real relationship between taxes, prices, and actual purchasing power across European countries**

[![SQL](https://img.shields.io/badge/SQL_Server-2019+-CC2927?logo=microsoft-sql-server&logoColor=white)](https://www.microsoft.com/en-us/sql-server)
[![Data Source](https://img.shields.io/badge/Data-Eurostat-0066A1?logo=eurostat&logoColor=white)](https://ec.europa.eu/eurostat)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Made with love](https://img.shields.io/badge/Made%20with-%E2%9D%A4-red)](https://github.com/)

## PROJECT OVERVIEW

1. SQL project combines three official **Eurostat datasets** to answer a simple but powerful question:

**"Do people in high-tax countries actually end up with less real purchasing power — or does high GDP and efficient spending offset the tax burden?"**

We calculate a **Real After-Tax Purchasing Power Index** that adjusts:
- GDP per capita in Purchasing Power Standards (PPS)
- Actual price level differences between countries
- Total tax wedge (including social contributions)

The result: a fair, apples-to-apples comparison of how far your income really goes in each European country from 2020 to 2024.

2. Tableau Visualization project

The Tableau dashboard contains 7 key visualizations:
 
- GDP per Capita vs Tax Rates
- After‑Tax Purchasing Power vs Tax Rates  
- After‑Tax Purchasing Power vs Tax Rates - Ranking
- After-Tax Purchasing Power vs Tax Rates - Distribution
- Purchasing Power Across Countries
- Tax Efficiency 
- Final Story Presentation (multi-slide Tableau story)

Each visualization answers a core analytical question and is optimized for stakeholder clarity.

3. Stakeholders presentation (PDF)

## Key Insights You Can Explore
1. Do higher taxes destroy living standards? (Spoiler: not always!)
2. Nordic model vs Eastern Europe: who wins after adjusting for cost of living?
3. Which country gives you the most "bang for your tax euro"?
4. What if you earn in Denmark but spend in Bulgaria? (Cross-country spending power simulation)

## Data Sources (Eurostat 2024)

| Dataset                             | Table Name               | Description                                      |
|-------------------------------------|--------------------------|--------------------------------------------------|
| Price level indices (EU27_2020=100) | `PriceLevelIndices`      | Comparative price levels across countries        |
| GDP per capita in PPS (EU27=100)    | `GDPPercapitaPPS`        | Income adjusted for purchasing power             |
| Implicit tax rate on labour         | `TaxRates`               | Total tax + social contributions as % of income  |

All data publicly available from [Eurostat](https://ec.europa.eu/eurostat/web/main/data/database)

## Database & Compatibility

- Microsoft SQL Server (2019+ recommended)
- Tested on SQL Server 2022 and Azure SQL Database
- Uses T-SQL features: `UNPIVOT`, `TRY_CAST`, `FULL OUTER JOIN`, CTEs, Window Functions

## Project Structure & Key Objects

TaxLifeIndex/
│
├── Tables (raw imported data)
│   ├── PriceLevelIndices
│   ├── GDPPercapitaPPS
│   └── TaxRates
│
├── Views (cleaned & unpivoted)
│   ├── v_PriceLevelIndices
│   ├── v_GDPPercapitaPPS
│   └── v_TaxRates
│
└── Main Analysis View
└── v_Europe_Economic_Dashboard  ← Main dashboard!

## Main Output Columns (v_Europe_Economic_Dashboard)

| Column                        | Meaning |
|-------------------------------|-------|
| `PurchasingPower_Index`       | Real income after cost-of-living adjustment (EU = 100) |
| `AfterTax_PurchasingPower`    | How much you actually keep and can spend after taxes |
| `TaxRate_pct`                 | Total tax burden (%) |
| `Rank_PurchasingPower`       | Yearly ranking by real purchasing power |
| `Rank_Lowest_TaxWedge`        | Who has the lowest taxes each year |

## How to Run

1. Create a new database called `TaxLifeIndex`
2. Import the three raw CSV files into tables (or use SSMS Import Wizard or `bcp`)
3. Run the script `Tax_and_Living_Standard_Analysis.sql` → it will:
   - Clean country names
   - Remove non-EU countries and aggregates
   - Unpivot years
   - Create clean views
   - Build the final dashboard view
4. Query `v_Europe_Economic_Dashboard` or run the example analytical queries at the bottom!

```sql
SELECT * FROM v_Europe_Economic_Dashboard 
WHERE Year = 2024 
ORDER BY AfterTax_PurchasingPower DESC;
```

## Example Findings (2024 preview)

Rank, Country, Tax Rate, Purchasing Power, After-Tax Power
1, Luxembourg, 38.5%, 180.2, 110.8
2, Ireland, 34.2%, 148.9, 98.1
3, Norway, 43.1%, 142.3, 81.0
..., Bulgaria, 30.1%, 68.4, 47.8

Even with high taxes, some countries still deliver top-tier living standards!

## Skills Demonstrated

1. SQL

Advanced data cleaning in SQL
UNPIVOT for wide-to-long transformation
Handling dirty real-world datasets (flags, text numbers, duplicates)
FULL OUTER JOIN + COALESCE for resilient merges
Calculated indices and ranking with window functions
CTEs and complex CASE logic
Cross-country "what-if" spending simulations

2. Tableau

-  Visualizations, Joins, Calculated Fields, Parameters, Story Board

## License
This project is licensed under the MIT License – free to use, modify, and share (including commercially).

## Author: [Orlin Data Analyst / GitHub OrlinDataAnalyst] – 2025

Star this repo if you found it useful for your economics, data analysis, or SQL portfolio!
