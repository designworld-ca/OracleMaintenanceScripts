. oraenv
<db_name>

rman target sys/<password> catalog <rmanDbUser>/<rmanDbPassword>@<rmandbserver>

show all;

run {
allocate channel ch1 device type 'sbt_tape' format 'RMAN_%d_%s_%t_%p.dbf' PARMS="SBT_LIBRARY=/opt/hds/Base/libobk.so,BLKSIZE=262144,ENV=(CvClientName=agonottsklxd010)" TRACE 0;
allocate channel ch2 device type 'sbt_tape' format 'RMAN_%d_%s_%t_%p.dbf' PARMS="SBT_LIBRARY=/opt/hds/Base/libobk.so,BLKSIZE=262144,ENV=(CvClientName=agonottsklxd010)" TRACE 0;
allocate channel ch3 device type 'sbt_tape' format 'RMAN_%d_%s_%t_%p.dbf' PARMS="SBT_LIBRARY=/opt/hds/Base/libobk.so,BLKSIZE=262144,ENV=(CvClientName=agonottsklxd010)" TRACE 0;
SQL 'Alter system switch logfile';
BACKUP TAG 'ORA_<dbName>_TAPE' RECOVERY AREA;
delete noprompt archivelog until time "<sysdate or sysdate -2>" all device type disk;
SQL 'Alter system switch logfile';
SQL 'Alter database backup controlfile to trace';
release channel 'ch1';
release channel 'ch2';
release channel 'ch3';
}
exit
CROSSCHECK BACKUP;
CROSSCHECK BACKUPSET;
CROSSCHECK ARCHIVELOG ALL;
