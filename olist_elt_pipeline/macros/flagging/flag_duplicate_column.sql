{% macro flag_duplicate_column(column_name, alias_name=None) -%}
    {#
        This macro returns a boolean flag indicating whether a value is duplicated 
        based on COUNT(*) OVER(PARTITION BY <column_name>) > 1.

        Args:
            column_name (str): The column to check for duplicates.
            alias_name (str, optional): The output column name. 
                                        Defaults to 'is_duplicate_<column_name>'.

        Returns:
            SQL expression: CASE WHEN COUNT(*) OVER (PARTITION BY <column_name>) > 1 
                             THEN TRUE ELSE FALSE END AS <alias_name>
    #}

    {%- set alias = (alias_name if alias_name is not none else 'is_duplicate_' ~ column_name) -%}

    CASE
        WHEN COUNT(*) OVER(PARTITION BY {{ column_name }}) > 1
        THEN TRUE
        ELSE FALSE
    END AS {{ alias }}

{%- endmacro %}