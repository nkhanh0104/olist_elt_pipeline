{% macro flag_missing_column(column_name, alias_name=None) -%}
    {# 
        This macro returns a boolean flag for missing (null) values in a given column.

        Args:
            column_name (str): The name of the column to check for NULLs.
            alias_name (str, optional): The name of the output flag column. 
                                        If not provided, defaults to 'is_missing_<column_name>'.

        Returns:
            SQL expression: CASE WHEN <column_name> IS NULL THEN TRUE ELSE FALSE END AS <alias_name>
    #}

    {%- set alias = (alias_name if alias_name is not none else 'is_missing_' ~ column_name) -%}

    CASE
        WHEN {{ column_name }} IS NULL
        THEN TRUE
        ELSE FALSE
    END AS {{ alias }}

{%- endmacro %}