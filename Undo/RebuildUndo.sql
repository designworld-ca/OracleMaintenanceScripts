CREATE UNDO TABLESPACE undo2 datafile '/u07/undo_redo/DNISC101/undotbs2_01.dbf' SIZE 1024M;

drop tablespace undotbs1 including contents and datafiles;

create undo tablespace UNDOTBS1 datafile '/u07/undo_redo/DNISC101/undotbs1_01.dbf' size 5000M;

ALTER TABLESPACE UNDOTBS1 ADD DATAFILE '/u08/undo_redo/DNISC101/undotbs1_02.dbf' size 5000M;

alter system set undo_tablespace=UNDOTBS1;
