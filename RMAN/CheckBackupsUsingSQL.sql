-- https://dbatricksworld.com/how-to-check-rman-backup-status-and-timings/


set linesize 500 pagesize 2000
col Hours format 9999.99
col STATUS format a10
select SESSION_KEY, INPUT_TYPE, STATUS,
to_char(START_TIME,'mm-dd-yyyy hh24:mi:ss') as RMAN_Bkup_start_time,
to_char(END_TIME,'mm-dd-yyyy hh24:mi:ss') as RMAN_Bkup_end_time,
elapsed_seconds/3600 Hours from V$RMAN_BACKUP_JOB_DETAILS
order by session_key;
