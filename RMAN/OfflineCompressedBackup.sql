SQL 'alter system archive log current';

# Full online compressed backup procedure for linux development

run
{
allocate channel ch1 device type disk format '/u##/backup/%U.bkp';
allocate channel ch2 device type disk format '/u##/backup/%U.bkp';
allocate channel ch3 device type disk format '/u##/backup/%U.bkp';
backup incremental level=0 as compressed backupset tag '<dbName>_FULL_LVL_0_20190625' database plus archivelog;
SQL 'Alter system switch logfile';
delete noprompt archivelog until time "sysdate - 2" all device type disk;
SQL 'Alter database backup controlfile to trace';
release channel ch1;
release channel ch2;
release channel ch3;
}
