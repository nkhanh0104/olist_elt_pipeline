{{
    config(
        materialized='view',
        alias='stg_customers',
    )
}}

-- Normalize columns
WITH casted AS (
    SELECT
        {{ cast_columns_from_schema(get_staging_schema_map('customers')) }}
    FROM {{ source('raw', 'customers') }}
),

-- Filter out row with missing critical PK/FK
filtered AS (
    SELECT
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    FROM casted
    WHERE
        customer_id IS NOT NULL
        AND customer_unique_id IS NOT NULL
),

-- Rank record duplicate customer_id order by customer_unique_id for easy to trace
ranked AS (
    SELECT
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY customer_unique_id) AS rn_customer_id_duplicate  --rank duplicate customer_id
    FROM filtered
),

-- Add flag to check missing and duplicated for another fill can use to analyze
flagged AS(
    SELECT
        customer_id,
        {{ flag_duplicate_column('rn_customer_id_duplicate','is_duplicate_customer_id') }},
        customer_unique_id,
        customer_zip_code_prefix,
        {{ flag_missing_column('customer_zip_code_prefix') }},
        {{ flag_duplicate_column('customer_zip_code_prefix') }},
        customer_city,
        {{ flag_missing_column('customer_city') }},
        {{ flag_duplicate_column('customer_city') }},
        customer_state,
        {{ flag_missing_column('customer_state') }},
        {{ flag_duplicate_column('customer_state') }},
        rn_customer_id_duplicate
    FROM ranked
)

/* Select only the first rn_customer_id_duplicate to deduplicate */
SELECT
    customer_id,
    is_duplicate_customer_id, -- kept to trace if necessary
    customer_unique_id,
    customer_zip_code_prefix,
    is_missing_customer_zip_code_prefix,
    is_duplicate_customer_zip_code_prefix,
    customer_city,
    is_missing_customer_city,
    is_duplicate_customer_city,
    customer_state,
    is_missing_customer_state,
    is_duplicate_customer_state
FROM flagged
WHERE rn_customer_id_duplicate = 1
