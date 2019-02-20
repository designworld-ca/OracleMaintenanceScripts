select file_name, status, online_status, tablespace_name 
from dba_data_files
where status <> 'AVAILABLE';


