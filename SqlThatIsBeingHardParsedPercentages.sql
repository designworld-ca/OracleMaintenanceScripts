select 'Soft Parses ' "Ratio"
,round(
((select sum(value) from v$sysstat where name = 'parse count (total)')
- (select sum(value) from v$sysstat where name = 'parse count (hard)'))
/(select sum(value) from v$sysstat where name = 'execute count')
*100,2)||'%' "percentage"
from dual
union
select 'Hard Parses ' "Ratio"
,round(
(select sum(value) from v$sysstat where name = 'parse count (hard)')
/(select sum(value) from v$sysstat where name = 'execute count')
*100,2)||'%' "percentage"
from dual
union
select 'Hard Parse Failures' "Ratio"
,round(
(select sum(value) from v$sysstat where name = 'parse count (failures)')
/(select sum(value) from v$sysstat where name = 'parse count (total)')
*100,2)||'%' "percentage"
from dual
