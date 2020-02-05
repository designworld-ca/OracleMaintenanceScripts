# Manual patching with Datapatch

## connect to server
## get list of all instances
ps -ef --sort=cmd | grep ora_smon
## for each instance
select PATCH_ID, ACTION_TIME, status from dba_registry_sqlpatch order by action_time desc;

## create blackout in OEM Cloud Control

## for each instance shutdown all databases
ALTER PLUGGABLE DATABASE ALL CLOSE IMMEDIATE;
shutdown immediate
lsnrctl stop

## confirm everything is down
ps -ef --sort=cmd | grep ora_smon

## relink if required
$ORACLE_HOME/bin/relink all

## for each instance startup all
STARTUP
## verify everything is open
SHOW PDBS
cd $ORACLE_HOME/OPatch
DATAPATCH -verbose


## on each instance where datapatch did something
STARTUP
## verify everything is open
SHOW PDBS

SET LINESIZE 800
SET PAGESIZE 1000
SET SERVEROUT ON
SET LONG 2000000

COLUMN action_time FORMAT A12
COLUMN patch_id FORMAT 999999999
COLUMN action FORMAT A12 
COLUMN status FORMAT A15
COLUMN description FORMAT A80


SELECT TO_CHAR(action_time, 'YYYY-MM-DD') AS action_time,
 patch_id,
 action,
 status,
 description
 FROM   sys.dba_registry_sqlpatch
 ORDER by action_time;
 

## ensure patch rollback is successful by checking that pdb are not restricted
select  status, message, action 
from   pdb_plug_in_violations 
where  status !='RESOLVED';



lsnrctl start

## delete blackout

