{{
    config(
        materialized='view',
        alias='stg_products',
    )
}}

-- Normalize columns
WITH casted AS (
    SELECT
        {{ cast_columns_from_schema(get_staging_schema_map('products')) }}
    FROM {{ source('raw', 'products') }}
),

-- Filter out row with missing critical PK/FK
filtered AS (
    SELECT
        product_id,
        product_category_name,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    FROM casted
    WHERE
        product_id IS NOT NULL
),

-- Rank record duplicate product_id order by product_id
ranked AS (
    SELECT
        product_id,
        product_category_name,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm,
        ROW_NUMBER() OVER(PARTITION BY product_id ORDER BY product_category_name NULLS LAST) AS rn_product_id_duplicate --rank duplicate product_id
    FROM filtered
),

-- Add flag to check missing and duplicated for another fill can use to analyze
flagged AS (
    SELECT
        product_id,
        {{ flag_duplicate_column('product_id') }},
        product_category_name,
        {{ flag_missing_column('product_category_name') }},
        product_name_length,
        {{ flag_missing_column('product_name_length') }},
        product_description_length,
        {{ flag_missing_column('product_description_length') }},
        product_photos_qty,
        {{ flag_missing_column('product_photos_qty') }},
        product_weight_g,
        {{ flag_missing_column('product_weight_g') }},
        product_length_cm,
        {{ flag_missing_column('product_length_cm') }},
        product_height_cm,
        {{ flag_missing_column('product_height_cm') }},
        product_width_cm,
        {{ flag_missing_column('product_width_cm') }},
        rn_product_id_duplicate
    FROM ranked
)

SELECT
    product_id,
    is_duplicate_product_id, -- kept to trace if necessary
    product_category_name,
    is_missing_product_category_name,
    product_name_length,
    is_missing_product_name_length,
    product_description_length,
    is_missing_product_description_length,
    product_photos_qty,
    is_missing_product_photos_qty,
    product_weight_g,
    is_missing_product_weight_g,
    product_length_cm,
    is_missing_product_length_cm,
    product_height_cm,
    is_missing_product_height_cm,
    product_width_cm,
    is_missing_product_width_cm
FROM flagged
WHERE rn_product_id_duplicate = 1