show parameter archive_lag


--if set to zero (the default) then the next statement will not show anything for optimal log file size
show parameter fast_start_mttr_target

select TARGET_MTTR, ESTIMATED_MTTR, OPTIMAL_LOGFILE_SIZE from v$INSTANCE_RECOVERY;

select * from v$mttr_target_advice order by mttr_target_for_estimate;

--adjust target accordingly
alter system set fast_start_mttr_target=30;
