{{ 
    config(
        materialized='view',
        alias='stg_order_reviews'
    )
}}

-- Normalize columns
WITH casted AS(
    SELECT
        {{ cast_columns_from_schema(get_staging_schema_map('order_reviews')) }}
    FROM {{ source('raw', 'order_reviews') }}
),

-- Filter invalid core fields for join or logic
filtered AS(
    SELECT
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_ts
    FROM casted
    WHERE
        review_id IS NOT NULL
        AND order_id IS NOT NULL
        /* Remove trash order_id not exist in the parent table */
        AND EXISTS (
            SELECT 1 FROM {{ source('raw', 'orders') }} o
            WHERE o.order_id = casted.order_id
        )
        AND review_creation_date IS NOT NULL
),

-- Rank record duplicate review_id order by review_creation_date
ranked_review_id AS (
    SELECT
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_ts,
        ROW_NUMBER() OVER(PARTITION BY review_id ORDER BY review_creation_date DESC) AS rn_review_id_duplicate --rank duplicate review_id
    FROM filtered
),

-- Remove duplicated review_id
dedup_review_id AS (
    SELECT
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_ts
    FROM ranked_review_id
    WHERE rn_review_id_duplicate = 1
),

-- Rank record duplicate order_id order by review_creation_date
ranked_order_id AS (
    SELECT
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_ts,
        ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY review_creation_date DESC) AS rn_order_id_duplicate --rank duplicate order_id
    FROM dedup_review_id
),

-- Remove duplicated order_id
dedup_order_id AS (
    SELECT
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_ts
    FROM ranked_order_id
    WHERE rn_order_id_duplicate = 1
)

/* Not use surrogate key to avoid potential false positives and ensure accurate data representation */
SELECT
    review_id,
    order_id,
    review_score,
    {{ flag_missing_column('review_score') }},
    review_comment_title,
    {{ flag_missing_column('review_comment_title') }},
    review_comment_message,
    {{ flag_missing_column('review_comment_message') }},
    review_creation_date,
    review_answer_ts,
    {{ flag_missing_column('review_answer_ts') }}
FROM dedup_order_id
