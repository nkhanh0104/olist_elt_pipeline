{{
    config(
        materialized='view',
        alias='stg_product_category_name_translation',
    )
}}

WITH casted AS(
    SELECT
        {{ cast_columns_from_schema(get_staging_schema_map('product_category_name_translation')) }}
    FROM {{ source('raw', 'product_category_name_translation') }}
),

-- Filter out row with missing critical PK/FK
filtered AS (
    SELECT
        product_category_name,
        product_category_name_english
    FROM casted
    WHERE
        product_category_name IS NOT NULL
        AND product_category_name_english IS NOT NULL
),

-- Rank record duplicate product_category_name
ranked AS (
    SELECT
        product_category_name,
        product_category_name_english,
        ROW_NUMBER() OVER(PARTITION BY product_category_name ORDER BY product_category_name_english NULLS LAST) AS rn_product_category_name_duplicate --rank duplicate product_category_name
    FROM filtered
),

-- Add flag to check missing and duplicated for another fill can use to analyze
flagged AS (
    SELECT
        product_category_name,
        {{ flag_duplicate_column('product_category_name') }},
        product_category_name_english,
        rn_product_category_name_duplicate
    FROM ranked
)

/* Select only the first rn_product_category_name_duplicate to deduplicate */
SELECT
    product_category_name,
    is_duplicate_product_category_name, -- kept to trace if necessary
    product_category_name_english
FROM flagged
WHERE rn_product_category_name_duplicate = 1