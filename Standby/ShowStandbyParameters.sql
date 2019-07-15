SELECT NAME, VALUE FROM v$parameter vp
WHERE vp.name IN( 'dg_broker_config_file1','dg_broker_start',
'log_archive_dest_1','log_archive_dest_2','log_archive_dest_3',
'log_archive_dest_state_1','log_archive_dest_state_2','log_archive_dest_state_3')
ORDER BY vp.NAME;
