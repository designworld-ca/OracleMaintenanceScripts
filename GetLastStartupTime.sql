SELECT to_char(startup_time,'DD-MON-YYYY HH24:MI:SS') "DB Startup Time"
FROM sys.v_$instance;