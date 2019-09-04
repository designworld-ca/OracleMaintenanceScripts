set oracle_sid=<dbName>
sqlplus / as sysdba
shutdown immediate
startup mount exclusive restrict
exit
rman 
connect target sys

drop database including backups noprompt;
exit

--delete empty folders
--delete admin trace folders
--run
--on windows stop database services first
sc delete <service name>

--delete from tnsnames and listener.ora
