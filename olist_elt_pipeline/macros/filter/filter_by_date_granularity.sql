{% macro filter_by_date_granularity(date_dim_alias) -%}
    {#
        🧠 Macro: filter_by_date_granularity
        📌 Purpose:
            Dynamically generate a WHERE clause to filter `dim_dates` by year, quarter, month, and day.
            Pulls values from dbt vars: year, quarter, month, day.
            Designed to support flexible date filtering in downstream fact tables.

        🧪 Rules:
        - ✅ If no date vars → returns `WHERE 1=1` (full data).
        - ✅ `year` is required if `quarter`, `month`, or `day` is provided.
        - ✅ If `quarter` is provided → do NOT pass `month` or `day`.
        - ✅ If `day` is provided → `month` is required.
        - ✅ Valid ranges:
            • year > 0
            • quarter: 1-4
            • month: 1-12
            • day: 1-31

        🧰 Usage in model:
            `SELECT ...
            FROM revenue_base r
            INNER JOIN dim_dates d ON r.order_purchase_date = d.date_day
            {{ filter_by_date_granularity('d') }}`

        🧰 Example CLI:
            dbt run --select fct_revenue_by_state --vars '{year: 2018, month: 7, day: 15}'
            dbt run --select fct_revenue_by_state --vars '{year: 2018, quarter: 3}'

    #}

    {%- set year = var('year', none) -%}
    {%- set month = var('month', none) -%}
    {%- set quarter = var('quarter', none) -%}
    {%- set day = var('day', none) -%}
    {%- set conditions = [] -%}

    {# 🛡 Validation: must pass dim_date_alias #}
    {%- if date_dim_alias is none -%}
        {{ exceptions.raise_compiler_error("❌ [filter_by_date_granularity] 'date_dim_alias' is required for macro to work.") }}
    {%- endif -%}

    {# 🛡 Validation: must have year if other granularity is provided #}
    {%- if year is none and (month is not none or day is not none or quarter is not none) -%}
        {{ exceptions.raise_compiler_error("❌ [filter_by_date_granularity] 'year' is required if you provide 'month', 'day', or 'quarter'.") }}
    {%- endif -%}

    {# ✅ year > 0 #}
    {%- if year is not none and year <= 0 -%}
        {{ exceptions.raise_compiler_error("❌ [filter_by_date_granularity] 'year' must be greater than 0.") }}
    {%- endif -%}

    {# ✅ quarter logic #}
    {%- if quarter is not none -%}
        {%- if quarter < 1 or quarter > 4 -%}
            {{ exceptions.raise_compiler_error("❌ [filter_by_date_granularity] Quarter must be between 1 and 4.") }}
        {%- endif -%}
        {%- if month is not none or day is not none -%}
            {{ exceptions.raise_compiler_error("❌ [filter_by_date_granularity] If 'quarter' is provided, do NOT provide 'month' or 'day'.") }}
        {%- endif -%}
    {%- endif -%}

    {# ✅ month logic #}
    {%- if month is not none -%}
        {%- if month < 1 or month > 12 -%}
            {{ exceptions.raise_compiler_error("❌ [filter_by_date_granularity] Month must be between 1 and 12.") }}
        {%- endif -%}
    {%- endif -%}

    {# ✅ day logic #}
    {%- if day is not none -%}
        {%- if month is none -%}
            {{ exceptions.raise_compiler_error("❌ [filter_by_date_granularity] 'day' requires 'month' to be provided.") }}
        {%- endif -%}
        {%- if day < 1 or day > 31 -%}
            {{ exceptions.raise_compiler_error("❌ [filter_by_date_granularity] Day must be between 1 and 31.") }}
        {%- endif -%}
    {%- endif -%}

    {# ✅ Build WHERE conditions #}
    {%- if year is not none -%}
        {% do conditions.append(date_dim_alias ~ ".year = " ~ year) %}
    {%- endif -%}
    {%- if quarter is not none -%}
        {%- do conditions.append(date_dim_alias ~ ".quarter = " ~ quarter) -%}
    {%- elif month is not none -%}
        {%- do conditions.append(date_dim_alias ~ ".month = " ~ month) -%}
        {%- if day is not none -%}
            {%- do conditions.append(date_dim_alias ~ ".day_of_month = " ~ day) -%}
        {%- endif -%}
    {%- endif -%}

    {%- if conditions | length == 0 -%}
        where 1=1
    {%- else -%}
        where {{ conditions | join(" and ") }}
    {%- endif -%}
{%- endmacro -%}
