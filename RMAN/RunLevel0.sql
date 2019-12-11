RUN {
crosscheck backup;
crosscheck archivelog all;
report obsolete;
delete noprompt obsolete;
Backup incremental level 0 database;
Backup archivelog all delete input;
Restore database validate;
}
EXIT;
