--removes all data from all non system tables to allow a manual import
--run these scripts in this order and save the output as three files

--1) disable all foreign key constraints
--note double quote on table names to accomodate names using oracle keywords
select 'alter table '||a.owner||'."'||a.table_name||'" disable constraint '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and a.r_owner not in
(select username from dba_users d where d.oracle_maintained = 'Y')
order by a.r_owner;

2) take the output of 1) and do a find and replace disable => enable


--3) truncate the tables but leave storage intact
--except for temporary tables
select 'TRUNCATE TABLE '||owner||'."'||object_name||DECODE(temporary,'N','" REUSE STORAGE','"')||';'
from all_objects where owner not in
(select username from dba_users d where d.oracle_maintained = 'Y')
and object_type = 'TABLE'
and owner != 'ADMIN_DBA'
and temporary = 'Y'
order by owner, object_name;

--run these scripts
--1)
--3)
--2)
--4)
EXEC UTL_RECOMP.recomp_parallel(4);
--5) check to show errors, should not be more than before
select count(*) from all_errors;
--6 analyzes all schemas
BEGIN
   FOR rec IN (SELECT *
                FROM all_users
                WHERE username NOT IN ('SYS','SYSDBA'))
    LOOP
        dbms_stats.gather_schema_stats(rec.username);
    END LOOP;
  END;
 /
