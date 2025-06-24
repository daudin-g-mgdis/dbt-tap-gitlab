with source as (

    select * from {{ var('schema') }}.file
    where filename = 'package.json'

),

parsed_json as (

    select
        project_id,
        commit_id,
        filename,
        filepath,
        fileurl,
        ref,
        content::json as content_json,
        date
    from source

),

dependencies_union as (

    -- Dependencies
    select
        project_id,
        commit_id,
        filename,
        filepath,
        fileurl,
        ref,
        date,
        'dependency' as type,
        key as dependency_name,
        value as version_raw
    from parsed_json,
    json_each_text(content_json -> 'dependencies')

    union all

    -- DevDependencies
    select
        project_id,
        commit_id,
        filename,
        filepath,
        fileurl,
        ref,
        date,
        'devDependency' as type,
        key as dependency_name,
        value as version_raw
    from parsed_json,
    json_each_text(content_json -> 'devDependencies')

),

version_split as (

    select
        dependency_name,
        type,
        case
            when version_raw like '^%' then '^'
            when version_raw like '~%' then '~'
            when version_raw like '=%' then '='
            else null
        end as selector,
        split_part(regexp_replace(version_raw, '^[^\d]*', ''), '.', 1) as version_major,
        split_part(regexp_replace(version_raw, '^[^\d]*', ''), '.', 2) as version_minor,
        split_part(regexp_replace(version_raw, '^[^\d]*', ''), '.', 3) as version_patch,
        project_id,
        commit_id,
        filename,
        filepath,
        fileurl,
        ref,
        date,
        version_raw
    from dependencies_union

)

select * from version_split
