-----------------------------------------------------------------
-- Buffer Cache Hit Ratio
-- Measures what percentage of requests for data is satisfied by data 
-- in the buffer cache. Higher percentages imply faster responses.
------------------------------------------------------------------
select 'Buffer Cache Hit Ratio = '|| round ((1 - 
(pr.value / (bg.value + cg.value))) * 100, 2)
from v$sysstat pr, v$sysstat bg, v$sysstat cg
where pr.name = 'physical reads'
and bg.name = 'db block gets'
and cg.name = 'consistent gets'

-----------------------------------------------------------------
-- Dictionary Cache Hit Ratio
-- Measures what percentage of requests for reference information 
-- about the database is satisfied by data in the dictionary cache. 
-- Higher percentages imply faster responses.
------------------------------------------------------------------
select 'Dictionary Cache Hit Ratio = '
|| round (sum (gets - getmisses) * 100 / sum (gets), 2)
from v$rowcache

--------------------------------------------------------------------
-- Sorts in Memory
-- Measures what percentage of data sorts occur within memory rather 
-- than in the sort segments on disk. Should be 100. 
--------------------------------------------------------------------
select 'Sorts in Memory = '
|| round ((mem.value / (mem.value + dsk.value)) * 100, 2)
from v$sysstat mem, v$sysstat dsk
where mem.name = 'sorts (memory)'
and dsk.name = 'sorts (disk)'

-------------------------------------------------------------------
-- Shared Pool Free
-- Measures the percentage of the shared pool not currently in use. 
-- Low free values are not a cause for concern except in combination 
-- with other factors that imply Oracle is out of RAM, such as poor 
-- dictionary cache hit ratio.
------------------------------------------------------------------
select 'Shared Pool Free = '
|| round ((sum (decode (name, 'free memory', bytes, 0)) 
/ sum (bytes)) * 100, 2)
from v$sgastat

------------------------------------------------------------------
-- Shared Pool Reloads
-- Measures the percentage of SQL and PL/SQL statements reloaded 
-- into the library cache as opposed to pinned in the cache. This 
-- should be low, because the more statements are found in the cache, 
-- the more efficiently Oracle will execute them.
--------------------------------------------------------------------
select 'Shared Pool Reloads = '
|| round (sum (reloads) / sum (pins) * 100, 2)
from v$librarycache
where namespace in ('SQL AREA', 'TABLE/PROCEDURE', 'BODY', 'TRIGGER')

--------------------------------------------------------------------
-- Library Cache Get Hit Ratio
-- Measures the percentage of requests for *any* object in the library 
-- cache that were satisfied by the cache, without reading from disk.
---------------------------------------------------------------------
select 'Library Cache Get Hit Ratio = '
|| round (sum (gethits) / sum (gets) * 100, 2)
from v$librarycache

-----------------------------------------------------------------
-- Recursive Calls versus Total Calls
-- Measures the proportion of recursive SQL calls as opposed to the 
-- total number of SQL calls, where "recursive" is Oracle jargon for 
-- SQL generated by the RDBMS background processes for internal 
-- purposes such as table sizing. This should be a low percentage; 
-- high percentages indicate that the RDBMS is doing a large amount 
-- of internal maintenance work, so it is probably not well tuned.
--------------------------------------------------------------------
select 'Recursive Calls vs Total Calls = '
|| round ((rcv.value / (rcv.value + usr.value)) * 100, 2)
from v$sysstat rcv, v$sysstat usr
where rcv.name = 'recursive calls'
and usr.name = 'user calls'

-------------------------------------------------------------------
-- Short versus Total Table Scans
-- Measures the proportion of full table scans that occur on short 
-- tables. A full table scan is faster than an index access if the 
-- table is small, so this figure should be high. If it is low, the 
-- system may be missing some indexes, or poorly coded SQL may be 
-- forcing the optimizer to choose against indexes.
-------------------------------------------------------------------
select 'Short vs Total Table Scans = '
|| round ((shrt.value / (shrt.value + lng.value)) * 100, 2)
from  v$sysstat shrt, v$sysstat lng
where shrt.name = 'table scans (short tables)'
and lng.name = 'table scans (long tables)'

--------------------------------------------------------------------
-- Redo Log Allocation Latch Contention
-- Compare this with the following latch query to see if either or 
-- both of the redo log latches is blocking. The redo logs are where 
-- recovery data is written in case of a system or hardware crash. 
-- The user process first grabs the copy latch, then grabs the 
-- allocation latch, allocates space in the redo log for a redo 
-- entry, releases the allocation latch, 
-- and then copies data into the allocated redo buffer and releases 
-- the copy latch.  
--------------------------------------------------------------------
select 'Redo Log Allocation Latch Contention = '
|| round (greatest ((sum (decode (ln.name, 'redo allocation', 
  misses, 0))
/ greatest (sum (decode (ln.name, 'redo allocation', gets, 0)), 1)),
(sum (decode (ln.name, 'redo allocation', immediate_misses, 0))
/ greatest (sum (decode (ln.name, 'redo allocation', immediate_gets, 
  0))
+ sum (decode (ln.name, 'redo allocation', immediate_misses, 0)), 1))
) * 100, 2)
from v$latch l, v$latchname ln
where  l.latch# = ln.latch#

-------------------------------------------------------------------
-- Redo Log Copy Latch Contention
-- See previous comment.
-------------------------------------------------------------------
select 'Redo Log Copy Latch Contention = '
|| round (greatest ((sum (decode (ln.name, 'redo copy', misses, 0))
/ greatest (sum (decode (ln.name, 'redo copy', gets, 0)), 1)),
(sum (decode (ln.name, 'redo copy', immediate_misses, 0))
/ greatest (sum (decode (ln.name, 'redo copy', immediate_gets, 0))
+ sum  (decode (ln.name, 'redo copy', immediate_misses, 0)), 1))
) * 100, 2)
from v$latch l, v$latchname ln
where l.latch# = ln.latch#

------------------------------------------------------------------
-- CPU Parse Overhead
-- Measures the proportion of database CPU time spent parsing. This 
-- figure should be very low. A high value shows that there is a 
-- large amount of once-only code in the database (e.g., dynamic 
-- SQL creation without bind variables) or that the shared SQL area 
-- is too small.
-----------------------------------------------------------------
select 'CPU Parse Overhead = '
|| round ((prs.value / (prs.value + exe.value)) * 100, 2)
from v$sysstat prs, v$sysstat exe
where prs.name like 'parse count (hard)'
and exe.name = 'execute count'