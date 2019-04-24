CREATE TABLE logger (
 log_ts                         TIMESTAMP NOT NULL
,routine_nm                     VARCHAR2(80 CHAR)
,log_txt                        VARCHAR2(4000 CHAR)
)
/

CREATE OR REPLACE PROCEDURE dbg(i_msg IN VARCHAR2, i_routine IN VARCHAR2 DEFAULT NULL) AS
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   INSERT INTO logger
   VALUES (LOCALTIMESTAMP, NVL(i_routine,'Unknown'), i_msg);
   COMMIT;  
END dbg;
/

CREATE VIEW ltr
AS SELECT * FROM logger
ORDER BY log_ts DESC
/
