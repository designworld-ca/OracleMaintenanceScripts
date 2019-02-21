DECLARE
  CURSOR MAX_FREE IS
    SELECT A.TABLESPACE_NAME,
           A.ALLOCATED_MB,
           A.USED_MB,
           A.MAX_SIZE_MB,
           A.MAX_FREE_MB,
           A.MAX_FREE_PCT
      FROM (SELECT TS.TABLESPACE_NAME,
                   DECODE(DT.CONTENTS,
                          'PERMANENT',
                          DECODE(DT.EXTENT_MANAGEMENT,
                                 'LOCAL',
                                 DECODE(DT.ALLOCATION_TYPE,
                                        'UNIFORM',
                                        'LM-UNI',
                                        'LM-SYS'),
                                 'DM'),
                          'TEMPORARY',
                          'TEMP',
                          DT.CONTENTS) TS_TYPE,
                   NVL(S.COUNT, 0) OBJECTS,
                   TS.FILES,
                   ROUND(TS.ALLOCATED / 1024 / 1024, 0) ALLOCATED_MB,
                   ROUND((TS.ALLOCATED - NVL(TS.FREE_SIZE, 0)) / 1024 / 1024,
                         0) USED_MB,
                   ROUND(MAXBYTES / 1024 / 1024, 0) MAX_SIZE_MB,
                   ROUND((MAXBYTES - (TS.ALLOCATED - NVL(TS.FREE_SIZE, 0))) / 1024 / 1024,
                         0) MAX_FREE_MB,
                   ROUND((MAXBYTES - (TS.ALLOCATED - NVL(TS.FREE_SIZE, 0))) * 100 /
                         MAXBYTES,
                         0) MAX_FREE_PCT
              FROM (SELECT DFS.TABLESPACE_NAME,
                           FILES,
                           ALLOCATED,
                           FREE_SIZE,
                           MAXBYTES
                      FROM (SELECT FS.TABLESPACE_NAME, SUM(FS.BYTES) FREE_SIZE
                              FROM DBA_FREE_SPACE FS
                             GROUP BY FS.TABLESPACE_NAME) DFS,
                           (SELECT DF.TABLESPACE_NAME,
                                   COUNT(*) FILES,
                                   SUM(DF.BYTES) ALLOCATED,
                                   SUM(DECODE(DF.MAXBYTES,
                                              0,
                                              DF.BYTES,
                                              DF.MAXBYTES)) MAXBYTES,
                                   MAX(AUTOEXTENSIBLE) AUTOEXTENSIBLE
                              FROM DBA_DATA_FILES DF
                             WHERE DF.STATUS = 'AVAILABLE'
                             GROUP BY DF.TABLESPACE_NAME) DDF
                     WHERE DFS.TABLESPACE_NAME = DDF.TABLESPACE_NAME
                    UNION
                    SELECT DTF.TABLESPACE_NAME,
                           FILES,
                           ALLOCATED,
                           FREE_SIZE,
                           MAXBYTES
                      FROM (SELECT TF.TABLESPACE_NAME,
                                   COUNT(*) FILES,
                                   SUM(TF.BYTES) ALLOCATED,
                                   SUM(DECODE(TF.MAXBYTES,
                                              0,
                                              TF.BYTES,
                                              TF.MAXBYTES)) MAXBYTES,
                                   MAX(AUTOEXTENSIBLE) AUTOEXTENSIBLE
                              FROM DBA_TEMP_FILES TF
                             GROUP BY TF.TABLESPACE_NAME) DTF,
                           (SELECT TH.TABLESPACE_NAME,
                                   SUM(TH.BYTES_FREE) FREE_SIZE
                              FROM V$TEMP_SPACE_HEADER TH
                             GROUP BY TABLESPACE_NAME) TSH
                     WHERE DTF.TABLESPACE_NAME = TSH.TABLESPACE_NAME) TS,
                   (SELECT S.TABLESPACE_NAME, COUNT(*) COUNT
                      FROM DBA_SEGMENTS S
                     GROUP BY S.TABLESPACE_NAME) S,
                   DBA_TABLESPACES DT,
                   V$PARAMETER P
             WHERE P.NAME = 'db_block_size'
               AND TS.TABLESPACE_NAME NOT LIKE '%UNDO%'
               AND TS.TABLESPACE_NAME NOT LIKE '%TEMP%'
               AND TS.TABLESPACE_NAME = DT.TABLESPACE_NAME
               AND TS.TABLESPACE_NAME = S.TABLESPACE_NAME(+)) A
     ORDER BY 1;
  --------------
  V_TS_ID NUMBER;
  NOT_IN_AWR EXCEPTION;
  V_TS_BLOCK_SIZE            NUMBER;
  V_BEGIN_SNAP_ID            NUMBER;
  V_END_SNAP_ID              NUMBER;
  V_BEGIN_SNAP_DATE          DATE;
  V_END_SNAP_DATE            DATE;
  V_NUMDAYS                  NUMBER;
  V_TS_BEGIN_SIZE            NUMBER;
  V_TS_END_SIZE              NUMBER;
  V_TS_GROWTH                NUMBER;
  V_COUNT                    NUMBER;
  V_TS_BEGIN_ALLOCATED_SPACE NUMBER;
  V_TS_END_ALLOCATED_SPACE   NUMBER;
  -------------------------------
  CURRENT_PCT_FREE NUMBER(3, 2);
  --enter a decimal like .20 for 20%
  DESIRED_PCT_FREE CONSTANT NUMBER(3, 2) := &DESIREDPCTFREE;
  CURRENT_MB_FREE    NUMBER(9);
  DESIRED_MB_FREE    NUMBER(9);
  MB_GROWTH_FORECAST NUMBER(9);
  MB_TO_ADD          NUMBER(9);
  MAX_FILE_GB        NUMBER(9) := 16384;  --16 Gb max file size
  FILES_TO_ADD       NUMBER(9);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Desired percentage free IS '||&DESIREDPCTFREE * 100||' PERCENT');
  FOR DFILES IN MAX_FREE LOOP
    CURRENT_PCT_FREE := dfiles.MAX_FREE_PCT * .01;
    CURRENT_MB_FREE  := dfiles.MAX_FREE_MB;
    BEGIN
      SELECT TS#
        INTO V_TS_ID
        FROM V$TABLESPACE
       WHERE NAME = DFILES.TABLESPACE_NAME;
      SELECT COUNT(*)
        INTO V_COUNT
        FROM DBA_HIST_TBSPC_SPACE_USAGE
       WHERE TABLESPACE_ID = V_TS_ID;
      IF V_COUNT = 0 THEN
        RAISE NOT_IN_AWR;
      END IF;
      SELECT BLOCK_SIZE
        INTO V_TS_BLOCK_SIZE
        FROM DBA_TABLESPACES
       WHERE TABLESPACE_NAME = DFILES.TABLESPACE_NAME;
      SELECT MIN(SNAP_ID),
             MAX(SNAP_ID),
             MIN(TRUNC(TO_DATE(RTIME, 'MM/DD/YYYY HH24:MI:SS'))),
             MAX(TRUNC(TO_DATE(RTIME, 'MM/DD/YYYY HH24:MI:SS')))
        INTO V_BEGIN_SNAP_ID,
             V_END_SNAP_ID,
             V_BEGIN_SNAP_DATE,
             V_END_SNAP_DATE
        FROM DBA_HIST_TBSPC_SPACE_USAGE
       WHERE TABLESPACE_ID = V_TS_ID;
      V_NUMDAYS := V_END_SNAP_DATE - V_BEGIN_SNAP_DATE;
    
      SELECT ROUND(MAX(TABLESPACE_SIZE) * V_TS_BLOCK_SIZE / 1024 / 1024, 2)
        INTO V_TS_BEGIN_ALLOCATED_SPACE
        FROM DBA_HIST_TBSPC_SPACE_USAGE
       WHERE TABLESPACE_ID = V_TS_ID
         AND SNAP_ID = V_BEGIN_SNAP_ID;
      SELECT ROUND(MAX(TABLESPACE_SIZE) * V_TS_BLOCK_SIZE / 1024 / 1024, 2)
        INTO V_TS_END_ALLOCATED_SPACE
        FROM DBA_HIST_TBSPC_SPACE_USAGE
       WHERE TABLESPACE_ID = V_TS_ID
         AND SNAP_ID = V_END_SNAP_ID;
      SELECT ROUND(MAX(TABLESPACE_USEDSIZE) * V_TS_BLOCK_SIZE / 1024 / 1024,
                   2)
        INTO V_TS_BEGIN_SIZE
        FROM DBA_HIST_TBSPC_SPACE_USAGE
       WHERE TABLESPACE_ID = V_TS_ID
         AND SNAP_ID = V_BEGIN_SNAP_ID;
      SELECT ROUND(MAX(TABLESPACE_USEDSIZE) * V_TS_BLOCK_SIZE / 1024 / 1024,
                   2)
        INTO V_TS_END_SIZE
        FROM DBA_HIST_TBSPC_SPACE_USAGE
       WHERE TABLESPACE_ID = V_TS_ID
         AND SNAP_ID = V_END_SNAP_ID;
      V_TS_GROWTH := V_TS_END_SIZE - V_TS_BEGIN_SIZE;
    
      IF (V_TS_GROWTH <= 0 OR V_NUMDAYS <= 0) THEN
      
        DBMS_OUTPUT.PUT_LINE(DFILES.TABLESPACE_NAME ||
                             ' NO DATA GROWTH WAS FOUND FOR TABLESPACE ');
      ELSE
        MB_GROWTH_FORECAST := ROUND((V_TS_GROWTH / V_NUMDAYS) * 90, 0);
        --calculate how much space is needed
        DESIRED_MB_FREE := (CURRENT_MB_FREE * DESIRED_PCT_FREE) /
                     CURRENT_PCT_FREE;
        --DBMS_OUTPUT.PUT_LINE(DESIRED_MB_FREE);
        MB_TO_ADD := TRUNC(DESIRED_MB_FREE + MB_GROWTH_FORECAST - CURRENT_MB_FREE);
        
        DBMS_OUTPUT.PUT_LINE(DFILES.TABLESPACE_NAME||' Current free Mb: '||CURRENT_MB_FREE||' Expected growth next 90 days: ' ||
                             MB_GROWTH_FORECAST ||
                             ' MB: Add '||GREATEST(MB_TO_ADD, 0)||' MB');


        --calculate how many datafiles to add
        FILES_TO_ADD := CEIL(MB_TO_ADD / MAX_FILE_GB);
        DBMS_OUTPUT.PUT_LINE(DFILES.TABLESPACE_NAME ||' add '||GREATEST(FILES_TO_ADD,0)||' datafiles of '||MAX_FILE_GB||' Gb');
      
      END IF;
    
    EXCEPTION
      WHEN NOT_IN_AWR THEN
        DBMS_OUTPUT.PUT_LINE(CHR(10));
        DBMS_OUTPUT.PUT_LINE(DFILES.TABLESPACE_NAME || ' Tablespace USAGE INFORMATION NOT FOUND IN AWR');
    END;
  
  END LOOP;

END;
