
SELECT owner, table_name, num_rows,  'DBMS_STATS.gather_table_stats('''||OWNER||''','''||TABLE_NAME||''');' AS TEXT
FROM dba_tables
WHERE owner NOT IN ('SYS','SYSTEM','DBSNMP','OUTLN','AVAIL','DMSYS','OLAPSYS','WMSYS','EXFSYS')
AND owner NOT LIKE 'INF%'  --informatica schemas are not used
AND num_rows BETWEEN 5000  AND  10000--tables smaller than 5000 rows are likely to be loaded in memory
AND tablespace_name IS NOT NULL  --partition tables dealt with separately
AND table_name NOT LIKE 'MV%' --materialized view dealt with separately
AND EXTRACT (YEAR FROM last_analyzed ) < EXTRACT(YEAR FROM SYSDATE)

UNION

SELECT ai.owner, ai.table_name, ai.num_rows  ,'DBMS_STATS.gather_index_stats('''||ai.OWNER||''','''||ai.INDEX_NAME||''');' AS text
FROM All_Indexes ai
WHERE ai.owner NOT IN ('SYS','SYSTEM','DBSNMP','OUTLN','AVAIL','DMSYS','OLAPSYS','WMSYS','EXFSYS')
AND ai.tablespace_name IS NOT NULL  --partition tables dealt with separately
AND ai.index_type='NORMAL'  --function based indexes dealt with separately
AND EXTRACT (YEAR FROM last_analyzed ) < EXTRACT(YEAR FROM SYSDATE) --not analyzed this year
AND ai.owner||ai.table_name IN
(
SELECT owner||table_name
FROM dba_tables
WHERE owner NOT IN ('SYS','SYSTEM','DBSNMP','OUTLN','AVAIL','DMSYS','OLAPSYS','WMSYS','EXFSYS')
AND owner NOT LIKE 'INF%'  --informatica schemas are not used
AND num_rows BETWEEN 5000  AND  10000--tables smaller than 5000 rows are likely to be loaded in memory
AND tablespace_name IS NOT NULL  --partition tables dealt with separately
AND table_name NOT LIKE 'MV%' --materialized view dealt with separately
AND EXTRACT (YEAR FROM last_analyzed ) < EXTRACT(YEAR FROM SYSDATE)
)
ORDER BY 1,2,4 DESC
