--shutdown OMS
cd /u01/app/oracle/product/oem13cR3/middleware/bin

 emctl stop oms -all
 
 --shutdown agent
 cd /u01/app/oracle/product/agent/agent_13.3.0.0.0/bin
 emctl stop agent
 
 --shutdown listener
 lsnrcl stop
 
 --shutdown database
 sqlplus / as sysdba
 ALTER PLUGGABLE DATABASE ALL CLOSE IMMEDIATE;
 SHUTDOWN IMMEDIATE
 
 --Startup
 sqlplus / as sysdba
 Startup
 SHOW PDBS
 
 --Listener
 lsnrctl status
 --Or
 lsnrctl start
 
 --agent
 cd /u01/app/oracle/product/agent/agent_13.3.0.0.0/bin
 emctl status agent
 --Or
 emctl start agent
 
 cd /u01/app/oracle/product/oem13cR3/middleware/bin

 emctl start oms
