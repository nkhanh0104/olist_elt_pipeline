{{
    config(
        materialized='view',
        alias='stg_sellers',
    )
}}

-- Normalize columns
WITH casted as (
    SELECT
        {{ cast_columns_from_schema(get_staging_schema_map('sellers')) }}
    FROM {{ source('raw', 'sellers') }}
),

-- Filter out row with missing critical PK/FK
filtered AS (
    SELECT
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    FROM casted
    WHERE
        seller_id IS NOT NULL
),

-- Rank record duplicate seller_id
ranked AS (
    SELECT
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state,
        ROW_NUMBER() OVER(PARTITION BY seller_id ORDER BY seller_id DESC) AS rn_seller_id_duplicate
    FROM filtered
),

-- Add flag to check missing and duplicated for another fill can use to analyze
flagged AS (
    SELECT
        seller_id,
        {{ flag_duplicate_column('seller_id') }},
        seller_zip_code_prefix,
        {{ flag_missing_column('seller_zip_code_prefix') }},
        {{ flag_duplicate_column('seller_zip_code_prefix') }},
        seller_city,
        {{ flag_missing_column('seller_city') }},
        {{ flag_duplicate_column('seller_city') }},
        seller_state,
        {{ flag_missing_column('seller_state') }},
        {{ flag_duplicate_column('seller_state') }},
        rn_seller_id_duplicate
    FROM ranked
)

/* Select only the first rn_seller_id_duplicate to deduplicate */
SELECT
    seller_id,
    is_duplicate_seller_id, -- kept to trace if necessary
    seller_zip_code_prefix,
    is_missing_seller_zip_code_prefix,
    is_duplicate_seller_zip_code_prefix,
    seller_city,
    is_missing_seller_city,
    is_duplicate_seller_city,
    seller_state,
    is_missing_seller_state,
    is_duplicate_seller_state
FROM flagged
WHERE rn_seller_id_duplicate = 1 -- To remove duplicate