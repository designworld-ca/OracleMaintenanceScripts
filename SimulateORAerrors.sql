-- to test if OEM Grid is working
-- log onto a monitored database and run these
-- change the 2 to a 3 to write it to the alert log and trace

exec dbms_system.ksdwrt(2,'ORA-00257: This is a test error message for monitoring and can be ignored.');
exec dbms_system.ksdwrt(2,'ORA-16038: This is a test error message for monitoring and can be ignored.');
exec dbms_system.ksdwrt(2,'ORA-01242: This is a test error message for monitoring and can be ignored.');
exec dbms_system.ksdwrt(2,'ORA-01243: This is a test error message for monitoring and can be ignored.');


--or from here http://marcel.vandewaters.nl/oracle/database-oracle/simulating-ora-errors

alter session set events '942 incident(SIMULATED_ERROR)';
drop table tablethatdoesnotexist;
alter session set events '942 trace name context off';
