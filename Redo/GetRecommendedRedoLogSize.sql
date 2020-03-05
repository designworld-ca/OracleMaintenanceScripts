SELECT
(SELECT ROUND(AVG(BYTES) / 1024 / 1024, 2) FROM V$LOG) AS "Redo size (MB)",
ROUND((20 / AVERAGE_PERIOD) * (SELECT AVG(BYTES)
FROM V$LOG) / 1024 / 1024, 2) AS "Recommended Size (MB)"
FROM (SELECT AVG((NEXT_TIME - FIRST_TIME) * 24 * 60) AS AVERAGE_PERIOD
FROM V$ARCHIVED_LOG
WHERE FIRST_TIME > SYSDATE - 3)
--enter period of peak log switching
AND TO_CHAR (FIRST_TIME, 'HH24:MI') BETWEEN '21:00' AND '22:00')
;