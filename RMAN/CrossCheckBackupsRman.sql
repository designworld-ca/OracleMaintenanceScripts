RUN {
show all;
crosscheck backup;
crosscheck archivelog all;
report obsolete;
delete noprompt obsolete;
}
EXIT;
