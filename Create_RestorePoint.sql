
sqlplus / as sysdba;

shutdown immediate;
startup mount;
alter database archivelog;
alter database open;

create restore point CLEAN_DB guarantee flashback database;

COLUMN scn FORMAT  99999999999999
COLUMN time FORMAT  A30
COLUMN name FORMAT  A10
PROMPT Viewing the guaranteed restore point
select name, scn, TO_CHAR(time,'YYYY-MM-DD HH:MI AM') as time from v$restore_point;


Verify the information about the newly created restore point. Also, note down the SCN# for reference and we will refer to it as "reference SCN#"

Flashback to the guaranteed restore point
Now, in order to restore your database to the guaranteed restore point, follow the steps below:

sqlplus / as sysdba;
COLUMN CURRENT_SCN format  99999999999999999999999
select current_scn from v$database;
shutdown immediate;
startup mount;
select name, scn, TO_CHAR(time,'YYYY-MM-DD HH:MI AM') as time from v$restore_point;
flashback database to restore point CLEAN_DB;
alter database open resetlogs;
select current_scn from v$database;
