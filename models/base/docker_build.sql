with source as (

    select * from {{ var('schema') }}.file
    where filename = 'Dockerfile'

),

docker_lines as (

    select
        project_id,
        commit_id,
        filename,
        filepath,
        fileurl,
        ref,
        date,
        unnest(string_to_array(content, E'\n')) as line
    from source

),

from_lines as (

    select *
    from docker_lines
    where line ilike 'from %'

),

parsed_from as (

    select
        project_id,
        commit_id,
        filename,
        filepath,
        fileurl,
        ref,
        date,
        line,
        regexp_replace(line, '^from\s+', '', 'i') as from_clause
    from from_lines

),

parsed_image as (

    select
        *,
        -- Extract image name (e.g., node)
        regexp_replace(from_clause, '^.*\/([^:]+):.*$', '\1') as image_name,
        -- Extract version major (e.g., 20)
        regexp_replace(from_clause, '^.*:([0-9]+).*$' , '\1') as version_major
    from parsed_from

)

select
    project_id,
    commit_id,
    filename,
    filepath,
    fileurl,
    ref,
    date,
    line as docker_from_line,
    image_name,
    version_major
from parsed_image
