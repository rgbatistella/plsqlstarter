CREATE OR REPLACE PACKAGE BODY mail
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      1997Dec30 Creation
bcoulam      2008May08 Complete rewrite.

<i>
    __________________________  LGPL License  ____________________________
    Copyright (C) 1997-2008 Bill Coulam

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
    
*******************************************************************************/
IS

--------------------------------------------------------------------------------
--                 PACKAGE CONSTANTS, VARIABLES, TYPES, EXCEPTIONS
--------------------------------------------------------------------------------
--gc_pkg_nm CONSTANT user_source.NAME%TYPE := 'mail';

-- Used to retain email target settings application-wide, or across multiple
-- calls to the MAIL package during a session if the user wishes to override
-- defaults set by the Default Email Targets parameter.
g_to_smtp    BOOLEAN;
g_to_file    BOOLEAN;
g_to_table   BOOLEAN;

g_smtp_host VARCHAR2(200); -- initialized by package
g_smtp_port PLS_INTEGER := 25;
g_email_file_dir typ.t_maxobjnm; -- initialized by package

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
PROCEDURE get_targets_for_env
(
   o_to_smtp  OUT BOOLEAN,
   o_to_table OUT BOOLEAN,
   o_to_file  OUT BOOLEAN
) IS
   l_str app_env_parm.parm_val%TYPE;
   l_str_targets str_tt;
   l_target_nm VARCHAR2(10); -- left-hand side of the tag/value pair
   
   PROCEDURE get_target_bool(i_str_target IN VARCHAR2, io_target IN OUT BOOLEAN)
   IS
      l_target_val VARCHAR2(10);
   BEGIN
      l_target_val := SUBSTR(i_str_target,INSTR(i_str_target,'=')+1);
      
   -- lowercase the whole thing to make matching easier
      IF (LOWER(l_target_val) IN ('y','yes','on','true','1')) THEN
         io_target := TRUE;
      ELSE
         io_target := FALSE;
      END IF;
   END get_target_bool;
   
BEGIN

   l_str := parm.get_val(DEFAULT_EMAIL_TARGETS);
   
   IF (l_str IS NOT NULL) THEN
      logs.dbg('Found '||DEFAULT_EMAIL_TARGETS||'. Parsing into individual targets...');
      l_str_targets := str.parse_list(l_str);
         
      FOR i IN l_str_targets.FIRST..l_str_targets.LAST LOOP
         l_target_nm := TRIM(SUBSTR(l_str_targets(i),1,INSTR(l_str_targets(i),'=')-1));
            
         IF (l_target_nm = TARGET_SMTP) THEN
            get_target_bool(l_str_targets(i), o_to_smtp);
         ELSIF (l_target_nm = TARGET_TABLE) THEN
            get_target_bool(l_str_targets(i), o_to_table);
         ELSIF (l_target_nm = TARGET_FILE) THEN
            get_target_bool(l_str_targets(i), o_to_file);
         END IF;
      END LOOP;
   ELSE
      logs.dbg('Could not find '||DEFAULT_EMAIL_TARGETS||' for '||env.get_env_nm||', so defaulting to table only.');
      o_to_smtp := FALSE;
      o_to_table := TRUE;
      o_to_file := FALSE;
   END IF;

   logs.dbg(DEFAULT_EMAIL_TARGETS||': '||l_str);
   
END get_targets_for_env;

--------------------------------------------------------------------------------
FUNCTION env_is_actionable(i_env_list IN VARCHAR2 DEFAULT NULL) RETURN BOOLEAN
IS
   l_process_email BOOLEAN;
BEGIN

   IF (i_env_list IS NOT NULL) THEN
      logs.dbg('Caller requested that email be processed only in: '||i_env_list);
      logs.dbg('Current environment: '||env.get_env_nm);

      IF (INSTR(LOWER(i_env_list), LOWER(env.get_env_nm)) > 0) THEN
         logs.dbg('Processing email...');
         l_process_email := TRUE;
      ELSE
         logs.dbg('Not correct environment. Skipping email...');
         l_process_email := FALSE;
      END IF;
   ELSE
      logs.dbg('Caller did not specify a list of environments to control processing. Will process by default.');
      l_process_email := TRUE;
   END IF;
   RETURN l_process_email;
END env_is_actionable;
   
--------------------------------------------------------------------------------
FUNCTION send_omail
(
   SMTPServer     IN VARCHAR2,
   toList         IN VARCHAR2,
   subject        IN VARCHAR2,
   body           IN CLOB,
   sender         IN VARCHAR2,
   replyTo        IN VARCHAR2,
   ccList         IN VARCHAR2,
   bccList        IN VARCHAR2,
   headerExtra    IN VARCHAR2,
   attachmentData IN BLOB,
   attachmentType IN VARCHAR2,
   attachmentName IN VARCHAR2
   ,errorMessage   OUT VARCHAR2
) RETURN NUMBER IS
   LANGUAGE JAVA name 
   'OraMail.Send(java.lang.String,
                 java.lang.String,
                 java.lang.String,
                 oracle.sql.CLOB,
                 java.lang.String,
                 java.lang.String,
                 java.lang.String,
                 java.lang.String,
                 java.lang.String,
                 oracle.sql.BLOB,
                 java.lang.String,
                 java.lang.String,
                 java.lang.String[]) return int';
                  
--------------------------------------------------------------------------------
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
FUNCTION get_targets RETURN VARCHAR2
IS
BEGIN

   RETURN
   TARGET_SMTP||'['||util.bool_to_str(g_to_smtp)||'] '||
   TARGET_TABLE||'['||util.bool_to_str(g_to_table)||'] '||
   TARGET_FILE||'['||util.bool_to_str(g_to_file)||']';
   
END get_targets;

--------------------------------------------------------------------------------
PROCEDURE set_targets
(
   i_smtp     IN BOOLEAN DEFAULT FALSE,
   i_table    IN BOOLEAN DEFAULT FALSE,
   i_file     IN BOOLEAN DEFAULT FALSE
)
IS
BEGIN
   logs.dbg('Setting targets into memory as SMTP['||util.bool_to_str(i_smtp)||
                                         '] Table['||util.bool_to_str(i_table)||
                                         '] File['||util.bool_to_str(i_file)||']'
            );
            
   g_to_smtp := i_smtp;
   g_to_table := i_table;
   g_to_file := i_file;

END set_targets;

--------------------------------------------------------------------------------
FUNCTION is_smtp_server_avail RETURN BOOLEAN IS

   lx_noop_err EXCEPTION;
   lx_ehlo_err EXCEPTION;
   lx_no_conn EXCEPTION;

   l_out_msg VARCHAR2(255);
   l_conn utl_tcp.connection;
   l_rc   INTEGER;
   
   FUNCTION get_code(i_return_str IN VARCHAR2) RETURN NUMBER
   IS
   BEGIN
      RETURN TO_NUMBER(SUBSTR(i_return_str,1,3));
   END get_code;
   
BEGIN
   -- Open the TCP connection to SMTP server ...
   logs.dbg('Opening TCP connection');
   l_conn := utl_tcp.open_connection(remote_host => g_smtp_host,
                                     remote_port => g_smtp_port,
                                     tx_timeout  => TCP_TIMEOUT_SECS);

   logs.dbg('utl_tcp.get_line(after connection)');
   l_out_msg := utl_tcp.get_line(l_conn, TRUE);
   logs.dbg('SMTP connection msg is '||l_out_msg);

   IF get_code(l_out_msg) <> CONN_OK THEN
      RAISE lx_no_conn;
   END IF;
   
   -- Identify self to SMTP server (a valid domain is important). Will probably 
   -- return a multiline response. If the lines are preceded by code 250, 
   -- everything is fine.
   logs.dbg('utl_tcp.write_line(EHLO)');
   l_rc := utl_tcp.write_line(l_conn, 'EHLO'||' '|| env.DOMAIN);
   logs.dbg('EHLO = '||l_rc);
   
   logs.dbg('utl_tcp.get_line(after EHLO)');
   l_out_msg := utl_tcp.get_line(l_conn, TRUE);
   logs.dbg('EHLO msg is '||l_out_msg);

   IF get_code(l_out_msg) <> SMTP_OK THEN
      RAISE lx_ehlo_err;
   END IF;

   -- Give the server a NOOP test
   logs.dbg('utl_tcp.write_line(NOOP)');
   l_rc := utl_tcp.write_line(l_conn, 'NOOP');
   logs.dbg('utl_tcp.write_line(NOOP) returned code '||l_rc);
   
   logs.dbg('utl_tcp.get_line(after NOOP)');
   l_out_msg := utl_tcp.get_line(l_conn, TRUE);
   logs.dbg('NOOP msg is '||l_out_msg);

   IF get_code(l_out_msg) <> SMTP_OK THEN
      RAISE lx_noop_err;
   END IF;

   logs.dbg('Quitting SMTP');
   l_rc := utl_tcp.write_line(l_conn, 'QUIT'); -- toss return code

   logs.dbg('Closing TCP connection');
   utl_tcp.close_connection(l_conn);
   RETURN TRUE;

EXCEPTION
   WHEN utl_tcp.network_error THEN
      logs.err('Unable to work with TCP connection'
              ,FALSE);
      RETURN FALSE;
   WHEN lx_no_conn THEN
      logs.err('SMTP Connection Rejected, SMTP Msg ['||l_out_msg||']'
              ,FALSE);
      RETURN FALSE;
   WHEN lx_ehlo_err THEN
      logs.err('Able to connect to '||g_smtp_host||', but EHLO failed with ['||l_out_msg||']'
              ,FALSE);
      utl_tcp.close_connection(l_conn); -- cleanup connection
      RETURN FALSE;
   WHEN lx_noop_err THEN
      logs.err('Able to handshake to '||g_smtp_host||', but NOOP failed with ['||l_out_msg||']'
              ,FALSE);
      utl_tcp.close_connection(l_conn); -- cleanup connection
      RETURN FALSE;
   
END is_smtp_server_avail;


--------------------------------------------------------------------------------
PROCEDURE upd_email
(
   i_email_id   IN app_email.email_id%TYPE,
   i_new_status IN app_email.sent_status%TYPE,
   i_smtp_error IN app_email.smtp_error%TYPE DEFAULT NULL
) IS
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   logs.dbg('Updating email '||i_email_id||' as '||i_new_status||
            util.ifnn(i_smtp_error,' due to '||i_smtp_error));

   UPDATE app_email
      SET sent_status = i_new_status,
          smtp_error = i_smtp_error,
          -- leave sent_dt alone unless caller passed in a new stamp
          sent_dt = DECODE(i_new_status,'Sent',SYSDATE,sent_dt)
    WHERE email_id = i_email_id;

   COMMIT;

END upd_email;

--------------------------------------------------------------------------------
PROCEDURE store_mail
(
   i_email_to       IN app_email.email_to%TYPE,
   i_email_subject  IN app_email.email_subject%TYPE,
   i_email_body     IN CLOB,
   -- the remaining parameters below are all optional
   i_email_from     IN app_email.email_from%TYPE DEFAULT NULL,
   i_email_replyto  IN app_email.email_replyto%TYPE DEFAULT NULL,
   i_email_cc       IN app_email.email_cc %TYPE DEFAULT NULL,
   i_email_bcc      IN app_email.email_bcc%TYPE DEFAULT NULL,
   i_email_extra    IN app_email.email_extra %TYPE DEFAULT NULL,
   i_attach         IN BLOB DEFAULT NULL,
   i_attach_file_nm IN VARCHAR2 DEFAULT NULL,
   i_env_list       IN VARCHAR2 DEFAULT NULL,
   -- the next four are only used by send_mail
   i_email_id       IN app_email.email_id%TYPE DEFAULT NULL,
   i_sent_dt        IN app_email.sent_dt%TYPE DEFAULT NULL,
   i_sent_status    IN app_email.sent_status%TYPE DEFAULT 'Not Sent',
   i_smtp_error     IN app_email.smtp_error%TYPE DEFAULT NULL
) IS
   PRAGMA AUTONOMOUS_TRANSACTION;

   l_body          app_email.email_body%TYPE;
   l_long_body     CLOB;
   l_email_id      app_email.email_id%TYPE;
   l_mime_type     typ.t_mime_type;
BEGIN

   IF (env_is_actionable(i_env_list)) THEN
   
      excp.assert(i_email_to IS NOT NULL AND
                  i_email_subject IS NOT NULL AND
                  i_email_body IS NOT NULL,
                  'To, Subject and Body cannot be empty.');
   
   
      IF (i_email_id IS NULL) THEN
           l_email_id := app_email_seq.NEXTVAL;
      ELSE
         l_email_id := i_email_id;
      END IF;
      
      IF (dbms_lob.getlength(i_email_body) > cnst.MAX_COL_LEN) THEN
         -- In testing 3940 did not work. This probably has something to do with the
         -- fact that app_email.email_body uses CHAR semantics.
         l_body := SUBSTR(i_email_body,1,3800)||
                   '{SEE APP_EMAIL.LONG_BODY FOR THE REMAINDER OF THIS MESSAGE}';

         l_long_body := i_email_body;

         logs.dbg('Length of long body is '||dbms_lob.getlength(l_long_body));

      ELSE
         l_body := CAST(i_email_body AS VARCHAR2);
      END IF;
      
      logs.dbg('Writing to APP_EMAIL using email_id: '||l_email_id);
      INSERT INTO app_email
         (email_id,
          app_id,
          email_to,
          email_subject,
          email_body,
          long_body,
          email_from,
          email_replyto,
          email_cc,
          email_bcc,
          email_extra,
          sent_status,
          sent_dt,
          smtp_error,
          otx_sync_col)
      VALUES
         (l_email_id,
          env.get_app_id,
          i_email_to,
          i_email_subject,
          l_body,
          l_long_body,
          i_email_from,
          i_email_replyto,
          i_email_cc,
          i_email_bcc,
          i_email_extra,
          NVL(i_sent_status, 'Not Sent'),
          DECODE(i_sent_dt, NULL, DECODE(i_sent_status,'Sent',SYSDATE,NULL), i_sent_dt),
          i_smtp_error,
          -- "Y" tags the row as new or changed so the optional Oracle Text index can 
          -- see it and resync (Text provides nice "single column" search of all fields 
          -- in all emails ever sent). If the status is Error, we don't want it
          -- it indexed, so we set it to N.
          DECODE(i_sent_status,'Error','N','Y')
          );
   
      IF (i_attach IS NOT NULL AND dbms_lob.getlength(i_attach) > 0) THEN
      
         excp.assert(i_attach_file_nm IS NOT NULL,
                     'Filename is required for email attachments');
      
         l_mime_type := util.get_mime_type(i_attach_file_nm);

         logs.dbg('File name ['||i_attach_file_nm||'] yielded MIME type ['||
                  l_mime_type||']. Adding attachment row in APP_EMAIL_DOC to email_id ['||
                  l_email_id||']');
                  
         INSERT INTO app_email_doc
            (email_doc_id,
             email_id,
             file_nm,
             doc_content,
             doc_size,
             mime_type,
             otx_doc_type,
             otx_lang_cd,
             otx_charset_cd)
         VALUES
            (app_email_doc_seq.NEXTVAL,
             l_email_id,
             i_attach_file_nm,
             i_attach,
             dbms_lob.getlength(i_attach),
             l_mime_type,
             util.get_otx_doc_type(l_mime_type),
             NULL, -- otx_lang_cd
             NULL); -- otx_charset_cd
      END IF;
   
      -- must commit as this is an autonomous tx proc   
      COMMIT;
   
   END IF; -- if we should process the email for this environment

END store_mail;

--------------------------------------------------------------------------------
PROCEDURE write_mail
(
   i_email_to       IN app_email.email_to%TYPE,
   i_email_subject  IN app_email.email_subject%TYPE,
   i_email_body     IN CLOB,
   -- the remaining parameters below are all optional
   i_email_from     IN app_email.email_from%TYPE DEFAULT NULL,
   i_email_replyto  IN app_email.email_replyto%TYPE DEFAULT NULL,
   i_email_cc       IN app_email.email_cc %TYPE DEFAULT NULL,
   i_email_bcc      IN app_email.email_bcc%TYPE DEFAULT NULL,
   i_email_extra    IN app_email.email_extra %TYPE DEFAULT NULL,
   i_env_list       IN VARCHAR2 DEFAULT NULL,
   i_email_id       IN app_email.email_id%TYPE DEFAULT NULL
)
IS
   -- Variables to handle long email bodies over 32K
   l_body_len INTEGER := 0;
   l_pos      NUMBER := 1;
   l_bytes    INTEGER := io.MAX_FILE_LINE_LEN;
   l_lines    typ.tas_maxvc2;
   -- Variables for writing to file
   l_email_filename VARCHAR2(200);
   l_email_id app_email.email_id%TYPE;
BEGIN
   
   IF (env_is_actionable(i_env_list)) THEN

      excp.assert(i_email_to IS NOT NULL AND
                  i_email_subject IS NOT NULL AND
                  i_email_body IS NOT NULL,
                  'To, Subject and Body cannot be empty.');
   
      IF (i_email_id IS NULL) THEN
         l_email_id := app_email_seq.NEXTVAL;
      ELSE
         l_email_id := i_email_id;
      END IF;
      
      -- Construct the filename for this email
      l_email_filename := (TO_CHAR(dt.get_sysdtm, 'YYYYMMDDHH24MI')||'_'||
                           env.get_app_cd||'_'||
                           TO_CHAR(l_email_id) || '.mail');
      
      l_lines(1) := 'Date: '||TO_CHAR(CAST(dt.get_sysdtm AS TIMESTAMP WITH TIME ZONE),
                                     'DD Mon YYYY HH24:MI:SS TZH:TZM')||str.lf||
                   'To: ' || i_email_to || str.lf ||
                   'From: '||NVL(i_email_from, env.get_schema_email_address) || str.lf ||
                   'Subject: ' ||i_email_subject || str.lf ||
                   util.ifnn(i_email_replyto,'Reply-To: ' || i_email_replyto || str.lf) ||
                   util.ifnn(i_email_cc,'Cc: ' || i_email_cc || str.lf) ||
                   util.ifnn(i_email_bcc,'Bcc: ' || i_email_bcc || str.lf) ||
                   'X-Mailer: '||JAVA_MAILER_ID|| str.lf ||
                   util.ifnn(i_email_extra, i_email_extra || str.lf) ||
                   str.lf; -- blank line between headers and body

      l_body_len := dbms_lob.getlength(i_email_body);

      logs.dbg('Email '||l_email_id||' is '||l_body_len||' bytes long.');
      
      IF (l_body_len <= io.MAX_FILE_LINE_LEN) THEN
         -- Format and construct the mail message
         l_lines(l_lines.COUNT+1) := i_email_body;
      ELSE
         WHILE l_pos < l_body_len LOOP
            l_lines(l_lines.COUNT+1) := dbms_lob.substr(i_email_body, l_bytes, l_pos);
            l_pos := l_pos + l_bytes;
            l_bytes := LEAST ( io.MAX_FILE_LINE_LEN, l_body_len - l_bytes );
         END LOOP;
      END IF;

      -- extra blank line and period on own line to end the message
      l_lines(l_lines.COUNT+1) := str.lf||str.lf||'.';

      logs.dbg('Writing '||l_email_filename||' to '||g_email_file_dir||
               ' using email_id: '||l_email_id);

      -- write the collection of lines to the file now
      io.write_lines(l_lines, l_email_filename, g_email_file_dir);
      
   END IF; -- if we should process the email for this environment
   
END write_mail;

--------------------------------------------------------------------------------
PROCEDURE send_mail
(
   i_email_to       IN app_email.email_to%TYPE,
   i_email_subject  IN app_email.email_subject%TYPE,
   i_email_body     IN CLOB,
   -- the remaining parameters below are all optional
   i_email_from     IN app_email.email_from%TYPE DEFAULT NULL,
   i_email_replyto  IN app_email.email_replyto%TYPE DEFAULT NULL,
   i_email_cc       IN app_email.email_cc %TYPE DEFAULT NULL,
   i_email_bcc      IN app_email.email_bcc%TYPE DEFAULT NULL,
   i_email_extra    IN app_email.email_extra %TYPE DEFAULT NULL,
   i_attach         IN BLOB DEFAULT NULL,
   i_attach_file_nm IN VARCHAR2 DEFAULT NULL,
   i_env_list       IN VARCHAR2 DEFAULT NULL
)
IS
   l_email_id app_email.email_id%TYPE;
   l_err_cd   INTEGER;
   l_err_msg  typ.t_maxcol;
   l_email_from app_email.email_from%TYPE;
BEGIN
   
   IF (env_is_actionable(i_env_list)) THEN

      excp.assert(i_email_to IS NOT NULL AND
                  i_email_subject IS NOT NULL AND
                  i_email_body IS NOT NULL,
                  'To, Subject and Body cannot be empty.');

      -- Fill From even though it can technically be empty
      l_email_from := NVL(i_email_from, env.get_schema_email_address);

      l_email_id := app_email_seq.NEXTVAL;
      logs.dbg('New email ID is '||l_email_id);
      
      logs.dbg(get_targets);
      logs.dbg(g_smtp_host);
      
      -- control blocks to adhere to specified email targets
      IF (g_to_table) THEN
         
         logs.dbg('Storing email '||l_email_id||' to table...');
         
         store_mail(i_email_to, i_email_subject, i_email_body, l_email_from, 
                    i_email_replyto, i_email_cc, i_email_bcc, i_email_extra, 
                    i_attach, i_attach_file_nm, i_env_list, l_email_id);
      END IF;

      IF (g_to_file) THEN

         logs.dbg('Writing email '||l_email_id||' to file...');

         write_mail(i_email_to, i_email_subject, i_email_body, l_email_from, 
                    i_email_replyto, i_email_cc, i_email_bcc, i_email_extra, 
                    i_env_list, l_email_id);
      END IF;

      IF (g_to_smtp) THEN

         logs.dbg('Sending email '||l_email_id||' to '||g_smtp_host||'...');

         l_err_cd := send_omail(g_smtp_host, i_email_to, i_email_subject, i_email_body,
                                l_email_from, i_email_replyto, i_email_cc, i_email_bcc, 
                                'X-Mailer: '||JAVA_MAILER_ID||str.crlf||i_email_extra,
                                i_attach, util.get_mime_type(i_attach_file_nm),
                                i_attach_file_nm,
                                l_err_msg
                                );
         logs.dbg('SMTP returned '||l_err_cd);
         
         IF (l_err_cd = cnst.SUCCESS) THEN
            IF (g_to_table) THEN          
               upd_email(l_email_id, 'Sent');
            END IF;
         ELSE
            IF (g_to_table) THEN
               upd_email(l_email_id, 'Error', 'SMTP Return Code ['||l_err_cd||'] Msg: '||l_err_msg);
            ELSE
               -- Even if the table email target is not sent, we will record the
               -- error in APP_EMAIL[_DOC] since we can capture the whole thing
               -- there including attachments, which we can't do with APP_LOG.

               logs.dbg('Storing email '||l_email_id||' error into table...');
         
               store_mail(i_email_to, i_email_subject, i_email_body, l_email_from, 
                          i_email_replyto, i_email_cc, i_email_bcc, i_email_extra, 
                          i_attach, i_attach_file_nm, NULL, l_email_id,
                          NULL, 'Error',
                          'SMTP Return Code ['||l_err_cd||'] Msg: '||l_err_msg);
            END IF;
         END IF;
      END IF;
   
   END IF; -- if we should process the email for this environment
   
END send_mail;








--------------------------------------------------------------------------------
-- The following half of the this package is the SMTP implementation adapted from
-- http://www.oracle.com/technology/sample_code/tech/pl_sql/htdocs/Utl_Smtp_Sample.html
-- Comment this half back in if the JavaMail interface above (send_mail) is not
-- working or if you have a policy about not using Java in the database. Go to
-- the URL above for some sample code on how to use these SMTP APIs to send
-- all sorts of complex emails, including those in Unicode, multiple attachments, etc.
--------------------------------------------------------------------------------
--FUNCTION get_address(i_add_list IN OUT VARCHAR2) RETURN VARCHAR2 IS
--
--   l_addr VARCHAR2(256);
--   i    PLS_INTEGER;
--
--   FUNCTION lookup_unquoted_char
--   (
--      str  IN VARCHAR2,
--      chrs IN VARCHAR2
--   ) RETURN PLS_INTEGER AS
--      c            VARCHAR2(5);
--      i            PLS_INTEGER;
--      len          PLS_INTEGER;
--      inside_quote BOOLEAN;
--   BEGIN
--      inside_quote := FALSE;
--      i            := 1;
--      len          := LENGTH(str);
--      WHILE (i <= len) LOOP
--      
--         c := SUBSTR(str, i, 1);
--      
--         IF (inside_quote) THEN
--            IF (c = '"') THEN
--               inside_quote := FALSE;
--            ELSIF (c = '\') THEN
--               i := i + 1; -- Skip the quote character
--            END IF;
--            GOTO next_char;
--         END IF;
--      
--         IF (c = '"') THEN
--            inside_quote := TRUE;
--            GOTO next_char;
--         END IF;
--      
--         IF (INSTR(chrs, c) >= 1) THEN
--            RETURN i;
--         END IF;
--      
--         <<next_char>>
--         i := i + 1;
--      
--      END LOOP;
--   
--      RETURN 0;
--   
--   END lookup_unquoted_char;
--
--BEGIN
--
--   i_add_list := LTRIM(i_add_list);
--   i         := lookup_unquoted_char(i_add_list, ',;');
--   IF (i >= 1) THEN
--      l_addr      := SUBSTR(i_add_list, 1, i - 1);
--      i_add_list := SUBSTR(i_add_list, i + 1);
--   ELSE
--      l_addr      := i_add_list;
--      i_add_list := '';
--   END IF;
--
--   i := lookup_unquoted_char(l_addr, '<');
--   IF (i >= 1) THEN
--      l_addr := SUBSTR(l_addr, i + 1);
--      i    := INSTR(l_addr, '>');
--      IF (i >= 1) THEN
--         l_addr := SUBSTR(l_addr, 1, i - 1);
--      END IF;
--   END IF;
--
--   RETURN l_addr;
--   
--END get_address;
--
----------------------------------------------------------------------------------
--PROCEDURE write_mime_header
--(
--   io_conn IN OUT NOCOPY utl_smtp.connection,
--   i_name  IN VARCHAR2,
--   i_value IN VARCHAR2
--) IS
--BEGIN
--   utl_smtp.write_data(io_conn, i_name || ': ' || i_value || utl_tcp.crlf);
--END write_mime_header;
--
----------------------------------------------------------------------------------
--PROCEDURE write_boundary
--(
--   io_conn IN OUT NOCOPY utl_smtp.connection,
--   i_last  IN BOOLEAN DEFAULT FALSE
--) AS
--BEGIN
--   IF (i_last) THEN
--      utl_smtp.write_data(io_conn, LAST_BOUNDARY);
--   ELSE
--      utl_smtp.write_data(io_conn, FIRST_BOUNDARY);
--   END IF;
--END write_boundary;
--
----------------------------------------------------------------------------------
--FUNCTION begin_session RETURN utl_smtp.connection IS
--   io_conn utl_smtp.connection;
--BEGIN
--   -- open SMTP connection
--   io_conn := utl_smtp.open_connection(g_smtp_host, g_smtp_port);
--   utl_smtp.helo(io_conn, env.DOMAIN);
--   RETURN io_conn;
--END begin_session;
--
----------------------------------------------------------------------------------
--PROCEDURE begin_mail_in_session
--(
--   io_conn       IN OUT NOCOPY utl_smtp.connection,
--   i_sender     IN VARCHAR2,
--   i_recipients IN VARCHAR2,
--   i_subject    IN VARCHAR2,
--   i_mime_type  IN VARCHAR2 DEFAULT 'text/plain',
--   i_priority   IN PLS_INTEGER DEFAULT NULL
--) IS
--   my_recipients VARCHAR2(32767) := i_recipients;
--   my_sender     VARCHAR2(32767) := i_sender;
--BEGIN
--
--   -- Specify i_sender's address (our server allows bogus address
--   -- as long as it is a full email address (xxx@yyy.com).
--   utl_smtp.mail(io_conn, get_address(my_sender));
--
--   -- Specify recipient(s) of the email.
--   WHILE (my_recipients IS NOT NULL) LOOP
--      utl_smtp.rcpt(io_conn, get_address(my_recipients));
--   END LOOP;
--
--   -- Start body of email
--   utl_smtp.open_data(io_conn);
--
--   -- Set "From" MIME header
--   write_mime_header(io_conn, 'From', i_sender);
--
--   -- Set "To" MIME header
--   write_mime_header(io_conn, 'To', i_recipients);
--
--   -- Set "i_subject" MIME header
--   write_mime_header(io_conn, 'i_subject', i_subject);
--
--   -- Set "Content-Type" MIME header
--   write_mime_header(io_conn, 'Content-Type', i_mime_type);
--
--   -- Set "X-Mailer" MIME header
--   write_mime_header(io_conn, 'X-Mailer', SMTP_MAILER_ID);
--
--   -- Set i_priority:
--   --   High      Normal       Low
--   --   1     2     3     4     5
--   IF (i_priority IS NOT NULL) THEN
--      write_mime_header(io_conn, 'X-i_priority', i_priority);
--   END IF;
--
--   -- Send an empty line to denotes end of MIME headers and
--   -- beginning of message body.
--   utl_smtp.write_data(io_conn, utl_tcp.crlf);
--
--   IF (i_mime_type LIKE 'multipart/mixed%') THEN
--      write_text(io_conn,
--                 'This is a multi-part message in MIME format.' || utl_tcp.crlf);
--   END IF;
--
--END begin_mail_in_session;
--
----------------------------------------------------------------------------------
--PROCEDURE end_mail_in_session(io_conn IN OUT NOCOPY utl_smtp.connection) IS
--BEGIN
--   utl_smtp.close_data(io_conn);
--END end_mail_in_session;
--
----------------------------------------------------------------------------------
--PROCEDURE end_session(io_conn IN OUT NOCOPY utl_smtp.connection) IS
--BEGIN
--   utl_smtp.QUIT(io_conn);
--END end_session;
--
----------------------------------------------------------------------------------
--PROCEDURE send
--(
--  i_sender     IN VARCHAR2,
--  i_recipients IN VARCHAR2,
--  i_subject    IN VARCHAR2,
--  i_msg        IN VARCHAR2
--) IS
--   io_conn utl_smtp.connection;
--BEGIN
--   io_conn := begin_mail(i_sender, i_recipients, i_subject);
--   write_text(io_conn, i_msg);
--   end_mail(io_conn);
--END send;
--
----------------------------------------------------------------------------------
--FUNCTION begin_mail
--(
--   i_sender     IN VARCHAR2,
--   i_recipients IN VARCHAR2,
--   i_subject    IN VARCHAR2,
--   i_mime_type  IN VARCHAR2 DEFAULT 'text/plain',
--   i_priority   IN PLS_INTEGER DEFAULT NULL
--) RETURN utl_smtp.connection IS
--   io_conn utl_smtp.connection;
--BEGIN
--   io_conn := begin_session;
--   begin_mail_in_session(io_conn,
--                         i_sender,
--                         i_recipients,
--                         i_subject,
--                         i_mime_type,
--                         i_priority);
--   RETURN io_conn;
--END begin_mail;
--
----------------------------------------------------------------------------------
--PROCEDURE write_text
--(
--   io_conn IN OUT NOCOPY utl_smtp.connection,
--   i_msg   IN VARCHAR2
--) IS
--BEGIN
--   utl_smtp.write_data(io_conn, i_msg);
--END write_text;
--
----------------------------------------------------------------------------------
--PROCEDURE write_mb_text
--(
--   io_conn    IN OUT NOCOPY utl_smtp.connection,
--   i_msg IN VARCHAR2
--) IS
--BEGIN
--   utl_smtp.write_raw_data(io_conn, utl_raw.cast_to_raw(i_msg));
--END write_mb_text;
--
----------------------------------------------------------------------------------
--PROCEDURE write_raw
--(
--   io_conn    IN OUT NOCOPY utl_smtp.connection,
--   i_msg IN RAW
--) IS
--BEGIN
--   utl_smtp.write_raw_data(io_conn, i_msg);
--END write_raw;
--
----------------------------------------------------------------------------------
--PROCEDURE attach_text
--(
--   io_conn     IN OUT NOCOPY utl_smtp.connection,
--   i_data      IN VARCHAR2,
--   i_mime_type IN VARCHAR2 DEFAULT 'text/plain',
--   i_inline    IN BOOLEAN DEFAULT TRUE,
--   i_filename  IN VARCHAR2 DEFAULT NULL,
--   i_last      IN BOOLEAN DEFAULT FALSE
--) IS
--BEGIN
--   begin_attachment(io_conn, i_mime_type, i_inline, i_filename);
--   write_text(io_conn, i_data);
--   end_attachment(io_conn, i_last);
--END attach_text;
--
----------------------------------------------------------------------------------
--PROCEDURE attach_base64
--(
--   io_conn     IN OUT NOCOPY utl_smtp.connection,
--   i_data      IN RAW,
--   i_mime_type IN VARCHAR2 DEFAULT 'application/octet-stream',
--   i_inline    IN BOOLEAN DEFAULT TRUE,
--   i_filename  IN VARCHAR2 DEFAULT NULL,
--   i_last      IN BOOLEAN DEFAULT FALSE
--) IS
--   i   PLS_INTEGER;
--   len PLS_INTEGER;
--BEGIN
--
--   begin_attachment(io_conn, i_mime_type, i_inline, i_filename, 'base64');
--
--   -- Split the Base64-encoded attachment into multiple lines
--   i   := 1;
--   len := utl_raw.LENGTH(i_data);
--   WHILE (i < len) LOOP
--      IF (i + max_base64_line_width < len) THEN
--         utl_smtp.write_raw_data(io_conn,
--                                 utl_encode.base64_encode(utl_raw.SUBSTR(i_data,
--                                                                         i,
--                                                                         max_base64_line_width)));
--      ELSE
--         utl_smtp.write_raw_data(io_conn,
--                                 utl_encode.base64_encode(utl_raw.SUBSTR(i_data,
--                                                                         i)));
--      END IF;
--      utl_smtp.write_data(io_conn, utl_tcp.crlf);
--      i := i + max_base64_line_width;
--   END LOOP;
--
--   end_attachment(io_conn, i_last);
--
--END attach_base64;
--
----------------------------------------------------------------------------------
--PROCEDURE begin_attachment
--(
--   io_conn        IN OUT NOCOPY utl_smtp.connection,
--   i_mime_type    IN VARCHAR2 DEFAULT 'text/plain',
--   i_inline       IN BOOLEAN DEFAULT TRUE,
--   i_filename     IN VARCHAR2 DEFAULT NULL,
--   i_transfer_enc IN VARCHAR2 DEFAULT NULL
--) IS
--BEGIN
--   write_boundary(io_conn);
--   write_mime_header(io_conn, 'Content-Type', i_mime_type);
--
--   IF (i_filename IS NOT NULL) THEN
--      IF (i_inline) THEN
--         write_mime_header(io_conn,
--                           'Content-Disposition',
--                           'inline; i_filename="' || i_filename || '"');
--      ELSE
--         write_mime_header(io_conn,
--                           'Content-Disposition',
--                           'attachment; i_filename="' || i_filename || '"');
--      END IF;
--   END IF;
--
--   IF (i_transfer_enc IS NOT NULL) THEN
--      write_mime_header(io_conn, 'Content-Transfer-Encoding', i_transfer_enc);
--   END IF;
--
--   utl_smtp.write_data(io_conn, utl_tcp.crlf);
--END begin_attachment;
--
----------------------------------------------------------------------------------
--PROCEDURE end_attachment
--(
--   io_conn IN OUT NOCOPY utl_smtp.connection,
--   i_last  IN BOOLEAN DEFAULT FALSE
--) IS
--BEGIN
--   utl_smtp.write_data(io_conn, utl_tcp.crlf);
--   IF (i_last) THEN
--      write_boundary(io_conn, i_last);
--   END IF;
--END end_attachment;
--
----------------------------------------------------------------------------------
--PROCEDURE end_mail(io_conn IN OUT NOCOPY utl_smtp.connection) IS
--BEGIN
--   end_mail_in_session(io_conn);
--   end_session(io_conn);
--END end_mail;

                      
--------------------------------------------------------------------------------
--                  PACKAGE INITIALIZATIOINS (RARELY USED)
--------------------------------------------------------------------------------
BEGIN
   get_targets_for_env(g_to_smtp, g_to_table, g_to_file);
   g_email_file_dir := parm.get_val('Default Email File Directory');
   g_smtp_host := parm.get_val('SMTP Host');
END mail;
/
