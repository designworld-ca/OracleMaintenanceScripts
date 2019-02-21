SELECT a.tablespace_name, --a.objects, a.files, 
a.allocated_mb, a.used_mb, a.max_size_mb, a.max_free_mb, a.max_free_pct
FROM
(SELECT ts.tablespace_name,
DECODE(dt.contents,'PERMANENT',DECODE(dt.extent_management,'LOCAL',DECODE(dt.allocation_type,'UNIFORM','LM-UNI','LM-SYS'),'DM'),'TEMPORARY','TEMP',dt.contents) ts_type,
NVL(s.count,0) objects,
ts.files,
ROUND(ts.allocated/1024/1024,0) allocated_mb,
ROUND((ts.allocated-nvl(ts.free_size,0))/1024/1024,0) used_mb,
ROUND(maxbytes/1024/1024,0) max_size_mb,
ROUND((maxbytes-(ts.allocated-nvl(ts.free_size,0)))/1024/1024,0) max_free_mb,
ROUND((maxbytes-(ts.allocated-nvl(ts.free_size,0)))*100/maxbytes,0) max_free_pct
FROM
(
SELECT dfs.tablespace_name,files,allocated,free_size,maxbytes
FROM
(SELECT fs.tablespace_name, sum(fs.bytes) free_size
FROM dba_free_space fs
GROUP BY fs.tablespace_name)
dfs,
(SELECT df.tablespace_name, count(*) files, sum(df.bytes) allocated,
sum(DECODE(df.maxbytes,0,df.bytes,df.maxbytes)) maxbytes, max(autoextensible) autoextensible
FROM dba_data_files df
WHERE df.status = 'AVAILABLE'
GROUP BY df.tablespace_name)
ddf
WHERE dfs.tablespace_name = ddf.tablespace_name
UNION
SELECT dtf.tablespace_name,files,allocated,free_size,maxbytes
FROM
(SELECT tf.tablespace_name, count(*) files, sum(tf.bytes) allocated,
sum(DECODE(tf.maxbytes,0,tf.bytes,tf.maxbytes)) maxbytes, max(autoextensible) autoextensible
FROM dba_temp_files tf
GROUP BY tf.tablespace_name)
dtf,
(SELECT th.tablespace_name, SUM (th.bytes_free) free_size
FROM v$temp_space_header th
GROUP BY tablespace_name)
tsh
WHERE dtf.tablespace_name = tsh.tablespace_name
) ts,
( SELECT s.tablespace_name, count(*) count
FROM dba_segments s
GROUP BY s.tablespace_name) s,
dba_tablespaces dt,
v$parameter p
WHERE p.name = 'db_block_size'
AND ts.tablespace_name = dt.tablespace_name
AND ts.tablespace_name = s.tablespace_name (+))a
WHERE a.max_free_pct < 35
ORDER BY 1;
