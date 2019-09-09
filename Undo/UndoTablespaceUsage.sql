--useful for ORA-01628:max # extents (32765) reached for rollback segment

SELECT DISTINCT STATUS,TABLESPACE_NAME, SUM(BYTES), COUNT(*) FROM DBA_UNDO_EXTENTS GROUP BY STATUS, TABLESPACE_NAME; 

select max(maxquerylen),max(tuned_undoretention) from v$undostat; 
select max(maxquerylen),max(tuned_undoretention) from DBA_HIST_UNDOSTAT; 
select sum(bytes) from dba_free_space where tablespace_name='UNDOTBS1'; 
