SELECT DISTINCT owner, segment_name
FROM   v$database_block_corruption dbc
       JOIN dba_extents e ON dbc.file# = e.file_id AND dbc.block# BETWEEN e.block_id and e.block_id+e.blocks-1
ORDER BY 1,2;
SELECT *
FROM v$database_block_corruption;
