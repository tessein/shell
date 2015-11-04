/* MySQL */
USE database;
SELECT  aColumn,
        DATE_FORMAT(FROM_UNIXTIME(timestampInMillis/1000), '%Y-%m-%d %H') theHour,
        COUNT(aColumn) tally,
        RPAD('', LN(COUNT(*)), '*') graph
        /*   OR RPAD('', FLOOR(COUNT(*)/10), '*') graph  */
FROM THETABLE WHERE /* SELECTION CRITERIA GOES HERE */ GROUP BY 1, 2;
