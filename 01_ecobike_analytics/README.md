
# Project 1: EcoBike Demand Analytics

**An End-to-End Analytics Engineering Pipeline with dbt & DuckDB**

## Project Overview

This project transforms raw urban mobility data from the [Kaggle Bike Sharing Demand Competition](https://www.kaggle.com/competitions/bike-sharing-demand) into a production-ready star schema. It demonstrates the modern data stack's capability to handle complex time-series data locally without expensive cloud infrastructure.

### 🎯 Objectives & Milestones

1. **Ingestion:** Load raw CSV data into a local high-performance database.
2. **Transformation:** Clean, cast, and engineer features from raw strings.
3. **Analysis**

---

## How dbt + DuckDB Work

In this project, we replace a traditional cloud warehouse (like Snowflake or BigQuery) with **DuckDB**, an in-process analytical database.

### 1. The Components

* **dbt Core:** The engine that compiles our SQL and manages dependencies.
* **DuckDB (`ecobike.duckdb`):** The storage layer. It is a single file on disk that acts like a full-scale warehouse.
* **`profiles.yml` (The Bridge):** This file tells dbt how to find the database. It contains the "credentials" and "location" of the DuckDB file.
* **`dbt_project.yml` (The Brain):** The global configuration. It defines project name, folder paths, and how models should be materialized (Views vs. Tables).


## 📂 Project Structure

```text
01_ecobike_analytics/
├── models/
│   ├── staging/          # "Cleaning Room": Renaming, casting, basic logic
│   └── marts/            # "Showroom": Final business-ready tables
├── seeds/                # Static CSVs loaded into the DB
├── tests/                # Custom data quality scripts
├── dbt_project.yml       # Global project settings
├── profiles.yml          # Local DB connection settings
└── pyproject.toml        # uv dependency management

```

---

## 🛠️ Setup & Execution Guide

### Step 1: Initialize Environment

Using `uv` for lightning-fast dependency management:

```bash
uv init
uv add dbt-core dbt-duckdb

```

### Step 2: Connection Testing (The "Debug" Phase)

Before running models, we must ensure the "Bridge" (`profiles.yml`) is working.

```bash
# Verify connection to the DuckDB file
uv run dbt debug --profiles-dir .

```

> **What to look for:** You should see `Connection test: [OK]`. If it fails, check that `profiles.yml` path matches the project directory.

### Step 3: Data Ingestion (Seeds)

Load the Kaggle `raw_bike_demand.csv` into the database:

```bash
uv run dbt seed --profiles-dir .

```

### Step 4: The Build Cycle (Transformation & Logic)

Run the staging and marts models:

```bash
uv run dbt run --profiles-dir .

```

* **Staging (`view`):** Logic is saved as a virtual layer (no extra storage).
* **Marts (`table`):** Data is physically written to the `.duckdb` file for fast querying.


## Analysis


1. 

```bash

  uv run dbt show --inline "
    select 
      rental_hour, 
      demand_window, 
      round(avg(total_rides), 2) as avg_rides_per_hour
    from {{ ref('demand_analysis') }} 
    group by 1, 2 
    order by 3 desc
  " --profiles-dir .

```

OUTPUT

```

| rental_hour | demand_window | avg_rides_per_hour |
| ----------- | ------------- | ------------------ |
|          17 | Evening Rush  |             468.77 |
|          18 | Evening Rush  |             430.86 |
|           8 | Morning Rush  |             362.77 |
|          16 | Evening Rush  |             316.37 |
|          19 | Evening Rush  |             315.28 |

```



- The Evening Dominance: 5:00 PM (17) is the absolute peak, with 468.77 rides on average.
- The Morning Surge: 8:00 AM (8) is the secondary peak.
- The city has a heavy "work-to-home" or "work-to-social" flow in the evening that is significantly higher than the morning commute. This suggests people might take the bus/train to work but prefer biking home (?)



2. 

```bash

    uv run dbt show --inline "     
    select 
        rental_hour, 
        demand_window, 
        round(avg(registered_rides), 2) as avg_registered,
        round(avg(casual_rides), 2) as avg_casual
    from {{ ref('demand_analysis') }} 
    where rental_hour in (17, 18, 8, 16, 19)
    group by 1, 2 
    order by 1
    " --profiles-dir .

```

OUTPUT

```
| rental_hour | demand_window | avg_registered | avg_casual |
| ----------- | ------------- | -------------- | ---------- |
|           8 | Morning Rush  |         341.23 |      21.54 |
|          16 | Evening Rush  |         241.29 |      75.08 |
|          17 | Evening Rush  |         393.32 |      75.44 |
|          18 | Evening Rush  |         369.46 |      61.40 |
|          19 | Evening Rush  |         266.20 |      49.07 |
```


- At 8:00 AM: You have 341 registered rides vs. only 21 casual rides.
- Insight: The morning peak is almost exclusively driven by subscribers. These are people using the bikes as a reliable utility to get to work or school. They don't "explore"; they commute.
- At 5:00 PM (17:00): Registered rides jump to 393, but casual rides more than triple compared to the morning, hitting 75.
- Insight: The evening is a mix. You have the same commuters going home, but you also have a surge of casual users. This could be tourists, people meeting friends for dinner, or locals who use the bike for leisure after work.
