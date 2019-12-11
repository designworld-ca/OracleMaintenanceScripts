RUN {
crosscheck backup;
crosscheck archivelog all;
delete noprompt obsolete;
Backup incremental level 1 database;
Backup archivelog all delete input;
}
EXIT;
