SELECT  *--SUM(BYTES)/1024/1024 "MB" 
FROM DBA_DATA_FILES
WHERE tablespace_name LIKE 'UNDO%';


SELECT SUM(BYTES)/1024/1024 "MB" ,STATUS 
FROM DBA_UNDO_EXTENTS GROUP BY STATUS;


select
    ( select sum(bytes)/1024/1024 from dba_data_files
       where tablespace_name like 'UND%' )  allocated,
    ( select sum(bytes)/1024/1024 from dba_free_space
       where tablespace_name like 'UND%')  free,
    ( select sum(bytes)/1024/1024 from dba_undo_extents
       where tablespace_name like 'UND%') USed
from dual;
