PROMPT see if there any existing proxy users
SELECT * FROM proxy_users;

PROMPT as dba grant proxy
ALTER USER EDB_RMS_JOB GRANT CONNECT THROUGH &PWRUSER;

PROMPT connect as the regular user
CONNECT &PWRUSER[EDB_MARKET_JOB]/&PASSWORD@&APPDB

PROMPT remove the privilege
ALTER USER edb_RMS_job REVOKE CONNECT THROUGH &PWRUSER ;

PROMPT verify the privilege is gone
SELECT * FROM proxy_users WHERE client = &PWRUSER;
