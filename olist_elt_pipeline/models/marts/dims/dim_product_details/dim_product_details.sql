{{
    config(
        materialized='table',
        alias='dim_product_details'
    )
}}

WITH cleaned_product AS (
    SELECT
        product_id,
        COALESCE(product_category_name, 'Others') AS product_category_name,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm,
        is_missing_product_name_length,
        is_missing_product_description_length,
        is_missing_product_photos_qty,
        is_missing_product_weight_g,
        is_missing_product_length_cm,
        is_missing_product_height_cm,
        is_missing_product_width_cm
    FROM {{ ref('stg_products') }}
)

SELECT
    p.product_id,
    p.product_category_name, -- kept to trace if necessary
    /* Set product_category_name_english as product_category_name in case there is no product_category_name_english */
    COALESCE(pcnt.product_category_name_english, p.product_category_name) AS product_category_name_english,

    /* Features for ML models (used to train churn prediction, etc.)*/
    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,

    /* Flags to check missing values(used to filter or analyze data quality in ML/fct) */
    p.is_missing_product_name_length,
    p.is_missing_product_description_length,
    p.is_missing_product_photos_qty,
    p.is_missing_product_weight_g,
    p.is_missing_product_length_cm,
    p.is_missing_product_height_cm,
    p.is_missing_product_width_cm
FROM cleaned_product p
LEFT JOIN {{ ref('stg_product_category_name_translation') }} pcnt
    ON p.product_category_name = pcnt.product_category_name
