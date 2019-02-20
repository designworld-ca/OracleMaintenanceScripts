SELECT  s1.sid ||' '||fnu.description||' has been blocking Sid '||s2.sid||': '|| s2.username
||' using program '||s2.program ||
' for '||s2.seconds_in_wait Blocking_Session                
FROM    v$lock l1   ,
        v$session s1,
        v$lock l2   ,
        v$session s2,
        BROO1APP.FND_USER fnu
WHERE   s1.sid                  =l1.sid
        AND s2.sid              =l2.sid
        AND l1.BLOCK            =1
        AND l2.request          > 0
        AND l1.id1              = l2.id1
        AND l1.id2              = l2.id2
        AND s1.username = fnu.oracle_user
        AND s2.seconds_in_wait >= 30;



