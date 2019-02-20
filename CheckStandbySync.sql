--Primary: 
select thread#,max(sequence#) from v$archived_log group by thread#;

--Standby: 
select thread#,max(sequence#) from v$archived_log where applied='YES' group by thread#;


------------alternate way-----------

--standby
select process, status, sequence# from v$managed_standby;




