# Olist ELT & ML Pipeline 🚀
[![Airflow CI/CD Pipeline](https://github.com/nkhanh0104/olist_elt_pipeline/actions/workflows/main.yml/badge.svg)](https://github.com/nkhanh0104/olist_elt_pipeline/actions/workflows/main.yml)
[![Elementary Report](https://img.shields.io/badge/Data%20Quality-Elementary-blue)](https://nkhanh0104.github.io/olist_elt_pipeline/elementary_report.html)

🚀 A complete Data Engineering pipeline project with:

✅ PySpark → Snowflake → dbt → Airflow → Metabase → ML  
✅ Airflow DAGs: ingest raw data, run dbt pipeline, train ML churn model  
✅ CI/CD with GitHub Actions (run dbt, tests, docs, reports)  
✅ Data Quality monitoring with dbt-expectations + Elementary  
✅ End-to-end reproducible setup (Docker, GitHub Actions, Local)

📊 **Analysis & Business Insight included** - with chart-based recommendations [PDF & Metabase Dashboards](#-metabase-dashboards)

📊 [Elementary Report](https://nkhanh0104.github.io/olist_elt_pipeline/elementary_report.html)

📂 [GitHub Repo](https://github.com/nkhanh0104/olist_elt_pipeline)

---

## 🗂 Table of Contents
- [📈 Overview](#-overview)
- [📊 Architecture](#-architecture)
- [🧰 Tech Stack](#-tech-stack)
- [📅 How to Run](#-how-to-run)
  - [🚢 Option 1: GitHub Actions](#-option-1-run-full-project-automatically-with-github-actions)
  - [🚢 Option 2: Docker](#-option-2-run-full-project-with-docker)
  - [🧬 Option 3: Local](#-option-3-run-locally-without-docker)
- [🚀 CI/CD Workflow](#-cicd-workflow)
- [📉 Key DAGs](#-key-dags)
- [📈 Metabase Dashboards](#-metabase-dashboards)
- [🧪 Testing & Data Quality](#-testing--data-quality)
- [📂 Project Structure](#-project-structure-detailed)
- [🚀 Highlights](#-highlights)
- [📩 Contact](#-contact)

---

## 📈 Overview

This project builds a full-stack data engineering pipeline for Olist's e-commerce dataset:

- Ingests raw CSVs using PySpark
- Loads into Snowflake (raw/staging/mart schemas)
- Transforms with dbt
- Trains a customer churn prediction model
- Creates dashboards in Metabase
- Automates pipeline via Apache Airflow
- Integrates CI/CD and deploys Elementary report to GitHub Pages

---

## 📊 Architecture

```text
[Raw CSVs]
     ↓  (PySpark)
[Snowflake Raw Schema]
     ↓  (dbt models)
[Snowflake Staging → Marts]
     ↓  (ML DAG)
[Churn Model Predictions]
     ↓  (Metabase)
[Dashboards + Monitoring]
```

---

## 🧰 Tech Stack

| Layer                  | Tools / Tech                                                   |
|------------------------|----------------------------------------------------------------|
| Ingestion              | PySpark                                                        |
| Data Warehouse         | Snowflake                                                      |
| Transformation         | dbt                                                            |
| Workflow Orchestration | Apache Airflow (Dockerized)                                    |
| ML                     | scikit-learn                                                   |
| Dashboarding           | Metabase                                                       |
| CI/CD                  | GitHub Actions                                                 |
| Data Quality           | Elementary, dbt_expectations, dbt_utils, dbt_project_evaluator |
| Reporting              | GitHub Pages (HTML report)                                     |

---

## 📅 How to Run
Prepare your Snowflake by your self or use this command and change your information
```bash
-- Use an admin role
USE ROLE ACCOUNTADMIN;

-- Create the `transform` role
CREATE ROLE IF NOT EXISTS TRANSFORM;
GRANT ROLE TRANSFORM TO ROLE ACCOUNTADMIN;

-- Create the default warehouse if necessary
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH;
GRANT OPERATE ON WAREHOUSE [YOUR_WAREHOUSE] TO ROLE TRANSFORM;
-- Database use for Olist project
CREATE OR REPLACE DATABASE [YOUR_DATABSE];
-- Schemas according to ELT standards
CREATE OR REPLACE SCHEMA [YOUR_DATABSE].RAW;
CREATE OR REPLACE SCHEMA [YOUR_DATABSE].STAGING;
CREATE OR REPLACE SCHEMA [YOUR_DATABSE].MART;
CREATE OR REPLACE SCHEMA [YOUR_DATABSE].ELEMENTARY;
CREATE OR REPLACE SCHEMA [YOUR_DATABSE].EVALUATOR;

-- General warehouse computing
CREATE OR REPLACE WAREHOUSE [YOUR_WAREHOUSE]
 WITH WAREHOUSE_SIZE = XSMALL
 AUTO_SUSPEND = 60
 AUTO_RESUME = TRUE;
-- Assign permissions (if you create your own user)
GRANT USAGE ON DATABASE [YOUR_DATABSE] TO ROLE SYSADMIN;
GRANT USAGE ON WAREHOUSE [YOUR_WAREHOUSE] TO ROLE SYSADMIN;
GRANT ALL ON SCHEMA [YOUR_DATABSE].RAW TO ROLE SYSADMIN;
GRANT ALL ON SCHEMA [YOUR_DATABSE].STAGING TO ROLE SYSADMIN;
GRANT ALL ON SCHEMA [YOUR_DATABSE].MART TO ROLE SYSADMIN;
GRANT ALL ON SCHEMA [YOUR_DATABSE].ELEMENTARY TO ROLE SYSADMIN;
GRANT ALL ON SCHEMA [YOUR_DATABSE].EVALUATOR TO ROLE SYSADMIN;

-- Create the `dbt` user and assign to role
CREATE USER IF NOT EXISTS dbt
  PASSWORD='[YOUR_PASSWORD]'
  LOGIN_NAME='[YOUR_USER_NAME]'
  MUST_CHANGE_PASSWORD=FALSE
  DEFAULT_WAREHOUSE='[YOUR_WAREHOUSE]'
  DEFAULT_ROLE=TRANSFORM
  DEFAULT_NAMESPACE='[YOUR_DATABSE].[YOUR_SCHEMA]'
  COMMENT='DBT user used for data transformation';
ALTER USER dbt SET TYPE = LEGACY_SERVICE;
GRANT ROLE TRANSFORM to USER dbt;

-- Set up permissions to role `transform`
GRANT ALL ON WAREHOUSE [YOUR_WAREHOUSE] TO ROLE TRANSFORM; 
GRANT ALL ON DATABASE [YOUR_DATABSE] to ROLE TRANSFORM;
GRANT ALL ON ALL SCHEMAS IN DATABASE [YOUR_DATABASE] to ROLE TRANSFORM;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE [YOUR_DATABSE] to ROLE TRANSFORM;
GRANT ALL ON ALL TABLES IN SCHEMA [YOUR_DATABSE].RAW to ROLE TRANSFORM;
GRANT ALL ON FUTURE TABLES IN SCHEMA [YOUR_DATABSE].RAW to ROLE TRANSFORM;

```

### 🚢 Option 1: Run Full Project automatically with GitHub Actions

1. Clone the repo

```bash
git clone https://github.com/nkhanh0104/olist_elt_pipeline.git
cd olist_elt_pipeline
```

2. Checkin the code to your GitHub
  
3. Configure secrets and variables in GitHub
- Go to your repository → olist_elt_pipeline → Settings → Secrets and variables → Action
- Tab Secrets → New Repository secret
- Note: See .env.sample for more details

| Repository secrets                      | Description                                                 |
|-----------------------------------------|-------------------------------------------------------------|
| AIRFLOW_PASSWORD                        | YOUR_SNOWFLAKE_PASSWORD_HERE                                |
| AIRFLOW__CORE__FERNET_KEY               | YOUR_FERNET_KEY_HERE                                        |
| AIRFLOW__DATABASE__SQL_ALCHEMY_CONN     | postgresql+psycopg2://airflow:airflow@postgres:5432/airflow |
| ELEMENTARY_ACCOUNT                      | ELEMENTARY_ACCOUNT                                          |
| ELEMENTARY_PASSWORD                     | YOUR_ELEMENTARY_PASSWORD_HERE                               |
| ELEMENTARY_USER                         | YOUR_ELEMENTARY_USER_HERE                                   |
| SNOWFLAKE_ACCOUNT                       | YOUR_SNOWFLAKE_ACCOUNT_HERE                                 |
| SNOWFLAKE_PASSWORD                      | YOUR_SNOWFLAKE_PASSWORD_HERE                                |
| SNOWFLAKE_USER                          | YOUR_SNOWFLAKE_USER_HERE                                    |

- Tab Variables → New Repository variable
- Note: See .env.sample for more details

| Repository variables                   | Description                    |
|----------------------------------------|--------------------------------|
| AIRFLOW_EMAIL                          | admin@example.com              |
| AIRFLOW_GID                            | 0                              |
| AIRFLOW_UID                            | 5000                           |
| AIRFLOW_USER                           | admin                          |
| AIRFLOW__CORE__DAGS_PAUSED_AT_CREATION | False                          |
| AIRFLOW__CORE__EXECUTOR                | LocalExecutor                  |
| AIRFLOW__CORE__LOAD_EXAMPLES           | False                          |
| DBT_FOLDER_NAME                        | olist_elt_pipeline             |
| DBT_PROJECT_NAME                       | olist_elt_pipeline             |
| DBT_VAR_DATE                           | null                           |
| DBT_VAR_MONTH                          | null                           |
| DBT_VAR_QUARTER                        | null                           |
| DBT_VAR_YEAR                           | null                           |
| DOCKER_REGISTRY_URL                    | ghcr.io                        |
| ELEMENTARY_DATABASE                    | YOUR_ELEMENTARY_DATABASE_HERE  |
| ELEMENTARY_ENV                         | DEV                            |
| ELEMENTARY_ROLE                        | YOUR_ELEMENTARY_ROLE_HERE      |
| ELEMENTARY_SCHEMA                      | YOUR_ELEMENTARY_SCHEMA_HERE    |
| ELEMENTARY_WAREHOUSE                   | YOUR_ELEMENTARY_WAREHOUSE_HERE |
| PROJECT_ROOT_DIR_AIRFLOW_VAR           | /opt/airflow                   |
| SNOWFLAKE_DATABASE                     | YOUR_SNOWFLAKE_DATABASE_HERE   |
| SNOWFLAKE_ENV                          | DEV                            |
| SNOWFLAKE_ROLE                         | YOUR_SNOWFLAKE_ROLE_HERE       |
| SNOWFLAKE_SCHEMA_MART                  | MART                           |
| SNOWFLAKE_SCHEMA_RAW                   | RAW                            |
| SNOWFLAKE_WAREHOUSE                    | YOUR_SNOWFLAKE_WAREHOUSE_HERE  |

4.  Configure GitHub Pages
- Go to your repository → olist_elt_pipeline → Settings → Pages → Source change Deploy from a branch to GitHub Actions

5. Try to checkin something to master branch then the pipeline will run automatically when there is a change on the master branch.

### 🚢 Option 2: Run Full Project with Docker

1. Clone the repo

```bash
git clone https://github.com/nkhanh0104/olist_elt_pipeline.git
cd olist_elt_pipeline
```

2. Set up environment variables

```bash
cp .env.example .env
# Then update Snowflake credential in .env
```

3. Open variables.json then update Snowflake credential the same with .env

4. Rename local compose file

```bash
mv docker-compose.local.yml docker-compose.yml
```

5. Grant permission for the project root folder

```bash
# Must be in project root due to I use Linux
sudo chown -R 50000:0 .
```

4. Build Docker images without cache

```bash
docker-compose build --no-cache
```

5. Start all services

```bash
docker-compose up
```

6. Open UIs
- Access Airflow at http://localhost:8080
- Set Airflow Variables by import variables.json to avoid DAG errors and enable triggers

7. Trigger DAGs:
- `ingest_raw_data_dag`
- `full_dbt_pipeline_dag` (includes generate profiles)
- `ml_churn_training_dag`

---

### 🧬 Option 3: Run Locally without Docker

Requires Python 3.10+, Spark 3.5+, dbt 1.7+

1. Set up environment variables
```bash
cp .env.example .env
# Then fill in required Snowflake credentials
```

2. Create virtual environment and install dependencies
```bash
./install_venv.sh
```

3. Activate virtual environment
```bash
source .venv/bin/activate
```

4. Ingest raw data into Snowflake (raw schema)
```bash
# Must be in project root with virtual env activated
source .venv/bin/activate
./ingest_all.sh
```

5. Generate dim_dates seed (if not available)
```bash
# Must be in project root and inside virtual env
python scripts/generate_dates_seed.py 2016-01-01 2018-12-31 olist_elt_pipeline/seeds/dim_dates.csv
```

6. Generate profiles yaml
```bash
# Must be in project root and inside virtual env
python scripts/generate_profiles.py
```

7. Run dbt pipeline
```bash
# Must be in dbt project folder and inside virtual env e.g: olist_elt_pipeline/olist_elt_pipeline
dbt deps
dbt seed
dbt run
dbt test
dbt docs generate && dbt docs serve # You can see docs here
edr report
```

7. Open Elementary UIs
- Elementary Report: e.g., /olist_elt_pipeline/edr_target/elementary_report.html (dbt folder name with /edr_target)

---

## 🚀 CI/CD Workflow

On push or PR:

- Run dbt compile/run/test
- Run elementary data quality checks
- Deploy HTML report to GitHub Pages: https://nkhanh0104.github.io/olist_elt_pipeline/elementary_report.html

GitHub Secrets and Variables are used for storing Snowflake credentials and GitHub Pages access token.

---

## 📉 Key DAGs

| DAG                       | Purpose                          |
|---------------------------|----------------------------------|
| ingest_raw_data_dag       | Load raw CSV to Snowflake        |
| full_dbt_pipeline_dag     | Run dbt models & tests           |
| ml_churn_training_dag     | Train churn prediction model     |

---

## 📈 Metabase Dashboards

- Revenue & Customer Churn Charts
  - 📥 [Download Insight PDF](https://github.com/nkhanh0104/olist_elt_pipeline/blob/master/analysis/Metabase%20-%20Olist%20Dashboard%20Revenue.pdf)
- Products Chart
  - 📥 [Download Insight PDF](https://github.com/nkhanh0104/olist_elt_pipeline/blob/master/analysis/Metabase%20-%20Olist%20Dashboard%20Products.pdf)
- Payments Chart
  - 📥 [Download Insight PDF](https://github.com/nkhanh0104/olist_elt_pipeline/blob/master/analysis/Metabase%20-%20Olist%20Dashboard%20Payments.pdf)

---

## 🧪 Testing & Data Quality

- ✅ All dbt tests and Elementary checks have been integrated and published.
- 📄 View the latest data quality and test report here:  
  👉 [Elementary Report](https://nkhanh0104.github.io/olist_elt_pipeline/elementary_report.html)

This includes:
- dbt schema tests and data tests
- dbt_expectations assertions
- dbt_project_evaluator checks
- Elementary freshness tests, anomalies, and run results

---

All tests are run automatically via GitHub Actions (CI/CD).

## 📂 Project Structure (Detailed)

```text
.
├── .github/        
│   └── workflows/
|       └── main.yml # GitHub Actions CI/CD workflows
├── analysis/                 # Metabase Dashboard
│   ├── Metabase - Olist Dashboard - Payments.pdf # Contains a chart of the most popular payment methods from 2016 - 2018
│   ├── Metabase - Olist Dashboard - Products.pdf # Contains chart of top 10 best selling products from 2016 - 2018
│   └── Metabase - Olist Dashboard - Revenue.pdf  # Contains charts of revenue from 2016 - 2018
├── dags/                     
│   ├── dbt_full_pipeline_dag.py                  # Airflow DAGs: dbt
│   ├── ingest_raw_data_dag.py                    # Airflow DAGs: ingestion
│   └── ml_churn_training_dag.py                  # Airflow DAGs: ML
├── data/                                         # Raw Olist CSVs
│   ├── olist_customers_dataset.csv
│   ├── olist_geolocation_dataset.csv
│   ├── olist_order_items_dataset.csv
│   ├── olist_order_payments_dataset.csv
│   ├── olist_order_reviews_dataset.csv
│   ├── olist_orders_dataset.csv
│   ├── olist_products_dataset.csv
│   ├── olist_sellers_dataset.csv
│   └── product_category_name_translation.csv
├── extract_load/
│   ├── utils/
|   |   ├── ingest_config.pyl                     # Use to map each table name to the path for each CSV file
|   |   └── spark_session.py                      # Use to create spark session
│   └── spark_ingest_generic.py                   # Use to ingest Raw CSv to Snowflake by using pyspark
├── olist_elt_pipeline/                           # dbt project folder
│   ├── macros/
|   |   ├── casting/
|   |   |   ├── cast_column.sql                   # Macro allows column casting and rename the column (if necessary)
|   |   |   ├── cast_column.yml                   # Macro document
|   |   |   ├── cast_columns_from_schema.sql      # Macro allows column casting and rename the column (if necessary) based on dictionary schema
|   |   |   └── cast_columns_from_schema.yml      # Macro document
|   |   ├── filter/
|   |   |   ├── filter_by_date_granularity.sql    # Macro to generate a WHERE clause to filter `dim_dates` table by year, quarter, month, and day.
|   |   |   └── filter_by_date_granularity.yml    # Macro document
|   |   ├── flagging/
|   |   |   ├── flag_duplicate_column.sql         # Macro returns a boolean flag indicating whether a value is duplicated in a given column
|   |   |   ├── flag_duplicate_column.yml         # Macro document
|   |   |   ├── flag_missing_column.sql           # Macro returns a boolean flag for missing (null) values in a given column
|   |   |   └── flag_missing_column.yml           # Macro document
|   |   ├── schema_config/
|   |   |   ├── get_staging_schema_map.sql        # Macro returns a dictionary mapping table names to their respective schemas
|   |   |   └── get_staging_schema_map.sql        # Macro document
|   |   ├── generate_schema_name.sql              # Macro to overwrite schema
|   |   └── generate_schema_name.yml              # Macro document
│   ├── models/                                   # dbt models: marts, sources, staging
│   ├── seeds/
|   |   ├── dim_dates.csv                         # CSV file generated from generate_dates_seed.py script
|   |   └── dim_dates.yml                         # Document and test
│   ├── dbt_project.yml                           # dbt config
│   └── packages.yml                              # Contains the packages needed for dbt
├── scripts/                                      # Helper scripts
│   ├── generate_dates_seed.py                    # Use to generate dim_dates.csv
│   └── generate_profiles.py                      # Use to generate profiles
├── .env.sample                                   # Sample env vars (copy to .env)
├── Dockerfile                                    # Docker setup
├── docker-compose.local.yml                      # Local dev Docker Compose config
├── docker-compose.yml                            # Full CI/CD Docker Compose file
├── ingest_all.sh                                 # Script to run all ingestion raw data from csv file jobs
├── install_venv.sh                               # Shell script to install Python virtualenv
├── requirements.txt                              # Python deps
└── variables.json                                # Use to import Airflow Variables
```

---

## 🚀 Highlights

- Full-stack orchestration with modular pipelines
- GitHub Actions for dbt + data quality CI/CD
- Production-ready Airflow + Docker setup
- Supports both local and containerized execution
- GitHub Pages auto-deployment for HTML reports
- dbt packages: dbt_expectations, dbt_project_evaluator, elementary, dbt_utils
- Metabase dashboard for business insights → see analysis/

---

## 📩 Contact

For feedback or questions: nguyennhukhanh010499@gmail.com  
GitHub: https://github.com/nkhanh0104/olist_elt_pipeline

---

Licensed under MIT.
