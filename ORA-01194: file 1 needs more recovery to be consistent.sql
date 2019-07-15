ORA-01194: file 1 needs more recovery to be consistent


SQL> alter database open resetlogs;
alter database open resetlogs
*
ERROR at line 1:
ORA-01194: file 1 needs more recovery to be consistent
ORA-01110: data file 1: '/u01/app/oracle/oradata/RTS_NEW/system_new.dbf'
Workaround for this error is to provide all the available archive log files to the recovery:

SQL> recover database using backup controlfile until cancel;
...
Specify log: {<RET>=suggested | filename | AUTO | CANCEL}
AUTO
Above command will apply all the available archive logs automatically. Now try to open database with resetlogs:

SQL> alter database open resetlogs;
If the error persists due to insufficient archive logs, do the following workaround:

SQL> shutdown immediate

ORA-01109: database not open
Database dismounted.
ORACLE instance shut down.
Startup database in mount mode:

SQL> startup mount

ORACLE instance started.
Total System Global Area 530288640 bytes
Fixed Size 2131120 bytes
Variable Size 310381392 bytes
Database Buffers 209715200 bytes
Redo Buffers 8060928 bytes
Database mounted.
Change "_allow_resetlogs_corruption" parameter to TRUE and undo_management parameter to MANUAL:

SQL> ALTER SYSTEM SET "_allow_resetlogs_corruption"= TRUE SCOPE = SPFILE;
SQL> ALTER SYSTEM SET undo_management=MANUAL SCOPE = SPFILE;
After doing above changes, shutdown database, and startup:

SQL> shutdown immediate
ORA-01109: database not open
Database dismounted.
ORACLE instance shut down.
SQL> startup mount
ORACLE instance started.
Total System Global Area 530288640 bytes
Fixed Size 2131120 bytes
Variable Size 310381392 bytes
Database Buffers 209715200 bytes
Redo Buffers 8060928 bytes
Database mounted.
Now try resetlogs:

SQL> alter database open resetlogs;
May crash, if so, mount and alter database open resetlogs or just alter database open

Database altered.

**DO NOT SKIP REBUILDING THE UNDO**
Create new undo tablespace and set “undo_tablespace” parameter to the new undo tablespace and change “undo_management” parameter to AUTO:

SQL> CREATE UNDO TABLESPACE undo2 datafile '/u07/undo_redo/DNISC101/undotbs2_01.dbf' SIZE 1024M;
Tablespace created.
SQL> alter system set undo_tablespace = undo2 scope=spfile;
System altered.
SQL> alter system set undo_management=auto scope=spfile;
System altered.
Now bounce your database.

SQL> shutdown immediate
SQL> startup
Rebuild original undo

create undo tablespace UNDOTBS1 datafile '/u07/undo_redo/DNISC101/undotbs1_01.dbf' size 5000M;
ALTER TABLESPACE UNDOTBS1 ADD DATAFILE '/u08/undo_redo/DNISC101/undotbs1_02.dbf' size 5000M;
alter system set undo_tablespace=UNDOTBS1;
drop tablespace undo2 including contents and datafiles;
shutdown immediate
startup;
