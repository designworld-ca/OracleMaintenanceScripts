--shows whether you are in a cdb or pdb
column DB_NAME format a12
column TYPE format a10

select decode(sys_context('USERENV', 'CON_NAME'),'CDB$ROOT',sys_context('USERENV', 'DB_NAME'),sys_context('USERENV', 'CON_NAME')) DB_NAME,
            decode(sys_context('USERENV','CON_ID'),1,'CDB','PDB') TYPE 
       from DUAL;
       
--shows all pdbs

SHOW PDBS
