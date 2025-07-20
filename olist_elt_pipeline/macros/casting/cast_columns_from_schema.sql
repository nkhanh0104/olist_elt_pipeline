{% macro cast_columns_from_schema(schema_map, table_alias='') %}
    {# 
        This macro generates a list of columns with their types and aliases based on the provided schema map.
        It casts each column to its specified type and applies an alias if provided.
        If no alias is provided, it uses the source column name.
    #}
   {% set results = [] %}
   {% for source_column_name, value in schema_map.items() %}
       {% set data_type = value if value is string else value['type'] %}
       {% set column_alias = value['alias'] if value is mapping and value.get('alias') else source_column_name %}
         {# 
              If table_alias is provided, prepend it to the source column name.
              Otherwise, use the source column name directly.
        #}
       {% set column_reference = (table_alias ~ '.' ~ source_column_name) if table_alias else source_column_name %}
       {% do results.append(cast_column(column_reference, data_type, column_alias)) %}
   {% endfor %}
   {{ return(results | join(',\n    ')) }}
{% endmacro %}