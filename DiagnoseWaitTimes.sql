SELECT *
FROM v$system_event
ORDER BY total_waits * time_waited DESC;

SELECT vs.SID, vs.event,vw.event wait_EVENT, vs.total_waits, vs.total_timeouts, vs.average_wait, vs.max_wait, vw.wait_class#, state
FROM v$session_event vs , v$session_wait vw
WHERE vs.WAIT_CLASS_ID = vw.WAIT_CLASS_ID
ORDER BY total_waits * time_waited DESC;

--buffer waits  http://www.morganslibrary.org/reference/wait_events.html
SELECT *
FROM (
  SELECT owner, object_name, subobject_name, object_type, tablespace_name TSNAME, value
  FROM gv$segment_statistics
  WHERE statistic_name='buffer busy waits'
  ORDER BY value DESC)
WHERE ROWNUM < 11;

--event status
--http://blog.tanelpoder.com/2008/08/07/the-simplest-query-for-checking-whats-happening-in-a-database/
select
count(*),
CASE WHEN state != 'WAITING' THEN 'WORKING'
ELSE 'WAITING'
END AS state,
CASE WHEN state != 'WAITING' THEN 'On CPU / runqueue'
ELSE event
END AS sw_event
FROM
v$session
WHERE
type = 'USER'
AND status = 'ACTIVE'
GROUP BY
CASE WHEN state != 'WAITING' THEN 'WORKING'
ELSE 'WAITING'
END,
CASE WHEN state != 'WAITING' THEN 'On CPU / runqueue'
ELSE event
END
ORDER BY
1 DESC, 2 DESC
/
