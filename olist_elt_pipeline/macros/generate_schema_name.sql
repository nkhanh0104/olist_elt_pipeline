{% macro generate_schema_name(custom_schema_name, node) -%}
    {# 
        This macro generates the schema name for a dbt resource (model, seed, snapshot) based on various conditions.
        It checks for custom schema definitions, specific package configurations, and falls back to the default schema.
        The order of precedence is as follows:
        1. Custom schema explicitly defined for the node.
        2. Specific schema for the 'dbt_project_evaluator_exception' model.
        3. Specific schema for models in the 'dbt_project_evaluator' package.
        4. Specific schema for models in the 'elementary' package.
        5. Default schema defined in the dbt profile (target.schema).
    #}
    {%- set default_schema = target.schema -%}

    {# 1. Check for a custom schema explicitly defined for this node.
       This applies to any resource (model, seed, or snapshot) in your project
       that uses '+schema:' in dbt_project.yml or 'config(schema=...)' in the file. #}
    {%- if custom_schema_name is not none -%}
        {{ custom_schema_name | trim }}

    {# 2. Handle specific cases for dbt_project_evaluator_exception.
       This will ensure the exception table/view goes into the 'evaluator' schema. #}
    {%- elif node.name | lower == 'dbt_project_evaluator_exception' and var('dbt_project_evaluator', {}).get('project_evaluator_schema') is not none -%}
        {{ var('dbt_project_evaluator').project_evaluator_schema | trim }}

    {# 3. Check specific vars for the 'dbt_project_evaluator' package (for its other models). #}
    {%- elif node.resource_type == 'model' and node.package_name == 'dbt_project_evaluator' and var('dbt_project_evaluator', {}).get('project_evaluator_schema') is not none -%}
        {{ var('dbt_project_evaluator').project_evaluator_schema | trim }}

    {# 4. Check specific vars for the 'elementary' package. #}
    {%- elif node.resource_type == 'model' and node.package_name == 'elementary' and var('elementary', {}).get('elementary_schema') is not none -%}
        {{ var('elementary').elementary_schema | trim }}

    {# 5. Fallback: If no specific schema is found through the above conditions,
       use the default schema defined in the dbt profile (target.schema). #}
    {%- else -%}
        {{ default_schema }}
    {%- endif -%}

{%- endmacro %}