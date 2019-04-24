DROP PROCEDURE print_send_ps_db;
DROP PROCEDURE log_msg;
DROP TABLE sol_log;

CREATE TABLE sol_log(
 log_ts TIMESTAMP NOT NULL
,log_msg VARCHAR2(4000) NOT NULL
,log_src VARCHAR2(128) NOT NULL
)
/

CREATE OR REPLACE PROCEDURE log_msg
(
   i_msg     IN VARCHAR2,
   i_msg_src IN VARCHAR2 DEFAULT NULL
) AS
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   INSERT INTO sol_log
      (log_ts
      ,log_msg
      ,log_src)
   VALUES
      (SYSTIMESTAMP
      ,i_msg
      ,NVL(i_msg_src, 'Unknown'));
   COMMIT;
END log_msg;
/

CREATE OR REPLACE PROCEDURE print_send_ps_db
(
  i_email_addr IN VARCHAR2 DEFAULT NULL
)
AS
   CURSOR cur_read_ps_db IS
      SELECT prob_src_nm
            ,prob_key
            ,prob_key_txt
            ,prob_notes
            ,sol_notes
            ,seq
        FROM (SELECT ps.prob_src_id
                    ,ps.prob_src_nm
                    ,p.prob_key
                    ,p.prob_key_txt
                    ,p.prob_notes
                    ,ROW_NUMBER() OVER(PARTITION BY s.prob_id ORDER BY s.sol_id) AS seq
                    ,s.sol_notes
                FROM ps_prob p
                JOIN ps_prob_src ps
                  ON ps.prob_src_id = p.prob_src_id
                JOIN ps_sol s
                  ON s.prob_id = p.prob_id)
       ORDER BY prob_src_id
               ,prob_key
               ,seq;
   
   file_rec   utl_file.file_type;
   marker     VARCHAR2(40); -- for debugging only
   idx        INTEGER := 0;
   filename   VARCHAR2(128) := 'ps_db_list_'||TO_CHAR(SYSDATE,'YYYYMMDD')||'.txt';
   file_err_msg VARCHAR2(256) := 'Unexpected error with UTL_FILE ops after marker @marker@ in print_send_ps_db.';
   -- email variables
   email_body CLOB := EMPTY_CLOB();
   db_name    VARCHAR2(10);
   to_addr    VARCHAR2(80);
   subj_hdr   VARCHAR2(100);
   -- performance test variables
   begin_time NUMBER;
   end_time   NUMBER;
   
   PROCEDURE handle_line(i_line IN VARCHAR2) IS
   BEGIN
      utl_file.put_line(file_rec, i_line);
      email_body := email_body || i_line || CHR(10);
   END handle_line;

BEGIN
   SELECT UPPER(name)
     INTO db_name
     FROM v$database;
     
   IF (i_email_addr IS NULL AND db_name <> 'MY10G') THEN
      log_msg('Error: NULL i_email_addr passed to print_send_ps_db. Destination address should be identified.');
      raise_application_error(-20001,'Parameter i_email_addr is empty. Please pass the desired destination of the emailed report.');
   END IF;

   -- Remove prior file run on same day
--   BEGIN
--      utl_file.fremove('CORE_DIR', filename);
--   EXCEPTION
--      WHEN utl_file.invalid_operation THEN
--         log_msg('ERROR: Cannot remove file '||filename);
--   END;
   
   begin_time := dbms_utility.get_time;
   
   marker   := 'fopen';
   file_rec := utl_file.fopen('CORE_DIR', filename, 'W', 32767);

   -- Read entire Problem/Solution database
   FOR l_rec IN cur_read_ps_db LOOP
      idx := idx + 1;
      -- Write each problem and its possible solutions to a file
   
   
      -- check to ensure file is open and handle is valid
      BEGIN
         marker := 'is_open';
         IF (utl_file.is_open(file_rec)) THEN
         
            -- write to file and email body at the same time
            marker := 'put_line';
            IF (idx = 1) THEN
               -- report header
               handle_line('********************************************************************************');
               handle_line('                Printout of the Problem/Solution Database');
               handle_line('                           '||TO_CHAR(SYSDATE, 'YYYY Month DD'));
               handle_line('********************************************************************************'||CHR(10));
               
            END IF;
            handle_line('Type [' || l_rec.prob_src_nm || '] Key [' ||
                        l_rec.prob_key || '] Error [' || l_rec.prob_key_txt || ']');
            handle_line('Comments:');
            handle_line(CHR(9) || l_rec.prob_notes);
            handle_line('Solution #'||l_rec.seq||':');
            handle_line(CHR(9) || l_rec.sol_notes || CHR(10));
            handle_line('--------------------------------------------');
         
         ELSE
            RAISE utl_file.invalid_filehandle;
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001
                                   ,REPLACE(file_err_msg,'@marker@',marker));
            log_msg(REPLACE(file_err_msg,'@marker@',marker), 'print_send_ps_db');
      END;
   END LOOP;

   BEGIN
      -- Now we are done writing lines, flush buffer (so line can be read immediately) and close file
      marker := 'fflush';
      utl_file.fflush(file_rec);
            
      marker := 'fclose';
      utl_file.fclose(file_rec);
   EXCEPTION
      WHEN OTHERS THEN
         raise_application_error(-20001
                                ,REPLACE(file_err_msg,'@marker@',marker));
         log_msg(REPLACE(file_err_msg,'@marker@',marker), 'print_send_ps_db');
   END;
   
   end_time := dbms_utility.get_time;
   log_msg('Reading table and writing to file took '||ROUND((end_time - begin_time)/100,2)||' seconds.');
   
   begin_time := dbms_utility.get_time;

   -- Send the file to my phone if in Production, otherwise to my email address
   IF (db_name <> 'XE') THEN
      to_addr := i_email_addr;
      subj_hdr := 'Unit Test Report: ';
   ELSIF (db_name = 'PROD') THEN
      to_addr := 'admin@boguscompany.com';
      subj_hdr := 'Production Report: ';
   END IF;
   
   -- This line requires that UTL_MAIL be installed (run $ORACLE_HOME/rdbms/admin/utlmail.sql and prvtmail.plb)
   -- and that your SMTP host be placed in the database init parameters, as in:
   -- ALTER SYSTEM SET smtp_out_server='smtp.yourdomain.com' SCOPE=SPFILE;
   -- Finally one must grant execute on UTL_MAIL to the schema housing this proc.
   /*
   UTL_MAIL.send(sender     => 'oracle@'||db_name||'.net',
                 recipients => to_addr,
                 subject    => subj_hdr||filename,
                 message    => email_body);
   */
   end_time := dbms_utility.get_time;

   log_msg('Sending email took '||ROUND((end_time - begin_time)/100,2)||' seconds.');
   
END print_send_ps_db;
/
