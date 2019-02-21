DECLARE
v_ts_id number;
not_in_awr EXCEPTION;
v_ts_block_size number;
v_begin_snap_id number;
v_end_snap_id number;
v_begin_snap_date date;
v_end_snap_date date;
v_numdays number;
v_ts_begin_size number;
v_ts_end_size number;
v_ts_growth number;
v_count number;
v_ts_begin_allocated_space number;
v_ts_end_allocated_space number;
cursor v_cur is select tablespace_name from dba_tablespaces where contents='PERMANENT';

BEGIN
FOR v_rec in v_cur
LOOP
BEGIN
SELECT ts# into v_ts_id FROM v$tablespace where name = v_rec.tablespace_name;
SELECT count(*) INTO v_count FROM dba_hist_tbspc_space_usage where tablespace_id=v_ts_id;
IF v_count = 0 THEN 
RAISE not_in_awr;
END IF ;
SELECT block_size into v_ts_block_size FROM dba_tablespaces where tablespace_name = v_rec.tablespace_name;
SELECT min(snap_id), max(snap_id), min(trunc(to_date(rtime,'MM/DD/YYYY HH24:MI:SS'))), max(trunc(to_date(rtime,'MM/DD/YYYY HH24:MI:SS')))
into v_begin_snap_id,v_end_snap_id, v_begin_snap_date, v_end_snap_date from dba_hist_tbspc_space_usage where tablespace_id=v_ts_id;
v_numdays := v_end_snap_date - v_begin_snap_date;

SELECT round(max(tablespace_size)*v_ts_block_size/1024/1024,2) into v_ts_begin_allocated_space from dba_hist_tbspc_space_usage where tablespace_id=v_ts_id and snap_id = v_begin_snap_id;
SELECT round(max(tablespace_size)*v_ts_block_size/1024/1024,2) into v_ts_end_allocated_space from dba_hist_tbspc_space_usage where tablespace_id=v_ts_id and snap_id = v_end_snap_id;
SELECT round(max(tablespace_usedsize)*v_ts_block_size/1024/1024,2) into v_ts_begin_size from dba_hist_tbspc_space_usage where tablespace_id=v_ts_id and snap_id = v_begin_snap_id;
SELECT round(max(tablespace_usedsize)*v_ts_block_size/1024/1024,2) into v_ts_end_size from dba_hist_tbspc_space_usage where tablespace_id=v_ts_id and snap_id = v_end_snap_id;
v_ts_growth := v_ts_end_size - v_ts_begin_size;
/*DBMS_OUTPUT.PUT_LINE(CHR(10));
DBMS_OUTPUT.PUT_LINE(v_rec.tablespace_name||' Tablespace Block Size: '||v_ts_block_size);
DBMS_OUTPUT.PUT_LINE('---------------------------');
DBMS_OUTPUT.PUT_LINE(CHR(10));
DBMS_OUTPUT.PUT_LINE('Summary');
DBMS_OUTPUT.PUT_LINE('========');
DBMS_OUTPUT.PUT_LINE('1) Allocated Space: '||v_ts_end_allocated_space||' MB'||' ('||round(v_ts_end_allocated_space/1024,2)||' GB)');
DBMS_OUTPUT.PUT_LINE('2) Used Space: '||v_ts_end_size||' MB'||' ('||round(v_ts_end_size/1024,2)||' GB)');
DBMS_OUTPUT.PUT_LINE('3) Used Space Percentage: '||round(v_ts_end_size/v_ts_end_allocated_space*100,2)||' %');
DBMS_OUTPUT.PUT_LINE(CHR(10));
DBMS_OUTPUT.PUT_LINE('History');
DBMS_OUTPUT.PUT_LINE('========');
DBMS_OUTPUT.PUT_LINE('1) Allocated Space on '||v_begin_snap_date||': '||v_ts_begin_allocated_space||' MB'||' ('||round(v_ts_begin_allocated_space/1024,2)||' GB)');
DBMS_OUTPUT.PUT_LINE('2) Current Allocated Space on '||v_end_snap_date||': '||v_ts_end_allocated_space||' MB'||' ('||round(v_ts_end_allocated_space/1024,2)||' GB)');
DBMS_OUTPUT.PUT_LINE('3) Used Space on '||v_begin_snap_date||': '||v_ts_begin_size||' MB'||' ('||round(v_ts_begin_size/1024,2)||' GB)' );
DBMS_OUTPUT.PUT_LINE('4) Current Used Space on '||v_end_snap_date||': '||v_ts_end_size||' MB'||' ('||round(v_ts_end_size/1024,2)||' GB)' );
DBMS_OUTPUT.PUT_LINE('5) Total growth during last '||v_numdays||' days between '||v_begin_snap_date||' and '||v_end_snap_date||': '||v_ts_growth||' MB'||' ('||round(v_ts_growth/1024,2)||' GB)');
*/
IF (v_ts_growth <= 0 OR v_numdays <= 0) THEN
DBMS_OUTPUT.PUT_LINE(CHR(10));
--DBMS_OUTPUT.PUT_LINE('!!! NO DATA GROWTH WAS FOUND FOR TABLESPACE '||v_rec.tablespace_name||' !!!');
ELSE
--DBMS_OUTPUT.PUT_LINE('6) Per day growth during last '||v_numdays||' days: '||round(v_ts_growth/v_numdays,2)||' MB'||' ('||round((v_ts_growth/v_numdays)/1024,2)||' GB)');
--DBMS_OUTPUT.PUT_LINE(CHR(10));
--DBMS_OUTPUT.PUT_LINE('Expected Growth');
--DBMS_OUTPUT.PUT_LINE('===============');
--DBMS_OUTPUT.PUT_LINE('1) Expected growth for next 90 days: '|| round((v_ts_growth/v_numdays)*90,2)||' MB'||' ('||round(((v_ts_growth/v_numdays)*30)/1024,2)||' GB)');
--DBMS_OUTPUT.PUT_LINE('2) Expected growth for next 180 days: '|| round((v_ts_growth/v_numdays)*180,2)||' MB'||' ('||round(((v_ts_growth/v_numdays)*60)/1024,2)||' GB)');
--DBMS_OUTPUT.PUT_LINE('3) Expected growth for next 270 days: '|| round((v_ts_growth/v_numdays)*270,2)||' MB'||' ('||round(((v_ts_growth/v_numdays)*90)/1024,2)||' GB)');
DBMS_OUTPUT.PUT_LINE(v_rec.tablespace_name||','||'Next 365 days: '|| round((v_ts_growth/v_numdays)*365,2)||' :MB'||' ('||round(((v_ts_growth/v_numdays)*365)/1024,2)||' :GB)'||',Next 730 days: '|| round((v_ts_growth/v_numdays)*730,2)||' :MB'||' ('||round(((v_ts_growth/v_numdays)*730)/1024,2)||' :GB,Next 1095 days: '|| round((v_ts_growth/v_numdays)*1095,2)||' :MB'||' ('||round(((v_ts_growth/v_numdays)*1095)/1024,2)||' :GB)');
--DBMS_OUTPUT.PUT_LINE(v_rec.tablespace_name||','||'Next 730 days: '|| round((v_ts_growth/v_numdays)*730,2)||' MB'||' ('||round(((v_ts_growth/v_numdays)*730)/1024,2)||' GB)');
--DBMS_OUTPUT.PUT_LINE(v_rec.tablespace_name||','||'Next 1095 days: '|| round((v_ts_growth/v_numdays)*1095,2)||' MB'||' ('||round(((v_ts_growth/v_numdays)*1095)/1024,2)||' GB)');
END IF;
--DBMS_OUTPUT.PUT_LINE('/\/\/\/\/\/\/\/\/\/\/\/ END \/\/\/\/\/\/\/\/\/\/\/\');

EXCEPTION
WHEN NOT_IN_AWR THEN
DBMS_OUTPUT.PUT_LINE(CHR(10));
DBMS_OUTPUT.PUT_LINE(v_rec.tablespace_name||' Tablespace');
DBMS_OUTPUT.PUT_LINE('--------------------');
DBMS_OUTPUT.PUT_LINE('Tablespace Block Size: '||v_ts_block_size);
DBMS_OUTPUT.PUT_LINE('---------------------------');
DBMS_OUTPUT.PUT_LINE(CHR(10));
DBMS_OUTPUT.PUT_LINE('!!! TABLESPACE USAGE INFORMATION NOT FOUND IN AWR !!!');
DBMS_OUTPUT.PUT_LINE('/\/\/\/\/\/\/\/\/\/\/\/ END \/\/\/\/\/\/\/\/\/\/\/\');
NULL;
END;
END LOOP;
END;
