
```
select sql_text,parse_calls, rows_processed, executions, version_count
from v$sqlarea 
where version_count > 1
and module is NULL;

 select parse_calls, executions
 from v$sql order by parse_calls desc;
 
 SELECT s2.name, SUM(s1.value)
  FROM v$sesstat s1 join v$statname s2 on s1.statistic# = s2.statistic#
 WHERE s2.name LIKE '%parse count%'
 GROUP BY s2.name
 ORDER BY 1,2;
``` 

