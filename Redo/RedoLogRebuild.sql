--on Linux 12c the database had to be bounced and recovered after doing this
--check carefully
--only drop when in inactive state
--check with this
set linesize 300
column REDOLOG_FILE_NAME format a50
SELECT
    a.GROUP#,
    a.THREAD#,
    a.SEQUENCE#,
    a.ARCHIVED,
    a.STATUS,
    b.MEMBER    AS REDOLOG_FILE_NAME,
    (a.BYTES/1024/1024) AS SIZE_MB
FROM v$log a
JOIN v$logfile b ON a.Group#=b.Group# 
ORDER BY a.GROUP# ASC;


--force a switch with 
alter system switch logfile;
alter system checkpoint;
-----------------------
alter database drop logfile group 1;
--delete files from os
ALTER DATABASE ADD LOGFILE GROUP 1 ('/u07/undo_redo/DOPS101/redo01a.log','/u08/undo_redo/DOPS101/redo01b.log') SIZE 256M REUSE;
----------------
alter database drop logfile group 2;
--delete files from os
ALTER DATABASE ADD LOGFILE GROUP 2 ('/u07/undo_redo/DOPS101/redo02a.log','/u08/undo_redo/DOPS101/redo02b.log') SIZE 256M REUSE;
---------------
alter database drop logfile group 3;
--delete files from os
ALTER DATABASE ADD LOGFILE GROUP 3 ('/u07/undo_redo/DOPS101/redo03a.log','/u08/undo_redo/DOPS101/redo03b.log') SIZE 256M REUSE;




recover database noparallel using backup controlfile until cancel;

alter database open resetlogs;


 You can have several ways to deal with your problems. However, it is a
must to backup all physical before doing any following actions:

1. (a) Startup the instance and mount it but do not open the database.
   (b) Drop the associated log file
   (c) Create a new log file

2. (a) Startup the instance and mount it but do not open the database.
   (b) open the database with resetlog option.

3. Carry out the same procedure as loss of an active online redo log
group as a last resort.
