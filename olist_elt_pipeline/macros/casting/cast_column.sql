{% macro cast_column(column_name, target_type,alias_column_name=None) %}
    {#
        This macro casts a column to a specified target type and set alias column name if provided.
        Note: Use column aliases only in SELECT. Avoid them in GROUP BY/ORDER BY/WHERE within the same query to prevent syntax errors.
        For GROUP BY/ORDER BY/WHERE, either repeat the full expression or use a macro that doesn not generate an alias.
    #}
    {%- if alias_column_name is none -%}
        {{ return("try_cast(" ~ column_name ~ " as " ~ target_type ~ ")") }}
    {%- else -%}
        {{ return("try_cast(" ~ column_name ~ " as " ~ target_type ~ ") as " ~ alias_column_name) }}
    {%- endif -%}
{% endmacro %}