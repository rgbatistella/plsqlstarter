CREATE OR REPLACE PACKAGE mail
  AUTHID CURRENT_USER
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

 A container for email-related routines. There are two sets, one dedicated to 
 using JavaMail (send_mail) and one dedicated to using UTL_SMTP/UTL_TCP (send, 
 begin_mail/end_mail and their attendant attachment routines). The second set is
 commented out to simplify things, but is available if the JavaMail implementation
 doesn't work for you. If you need to send multiple attachments, you'll need the
 second set, since the JavaMail implementation was built to support only one
 attachment.
 
%note
 Valid formats for email addresses are:
  user_id@mycompany.com
  "Full Name" <user_id@mycompany.com>
  Full Name <user_id@mycompany.com>

%usage
 Since this package appears overly complex, I wanted to provide some sample
 usage here at the top to indicate how simple it can be to send an email from
 within the database.
 
 First ensure that you have set up the SMTP Host and Default Email Targets
 parameters in the framework's parameter tables (APP_PARM, APP_ENV, APP_ENV_PARM).
 See send_mail below for further info on how to do that.
 
 EXAMPLE 1
 --------------------------------------
 To send a simple email:
 <code>
    -- assuming i_report_txt is a VARCHAR2 parameter filled by a previous query
    mail.send_mail('mymanager@mycompany.com','Daily Top SQL', i_report_txt);
 </code>
 
 To send a simple email to many recipients, pass in comma-delimited lists of
 email addresses in the To, Reply-To, Cc, and Bcc fields. These lists could
 be hard-coded, stored in the parameter tables, or dynamically generated using 
 the roles and/or environment data structures in the framework (you could have
 an email list parameter that is different in prod, dev and test for example).
 
 EXAMPLE 2
 --------------------------------------
 Here we send a report to a list of directors, copying a list of managers, with
 a high priority, asking for email processing only if this is a production or
 staging database.
 <code>
    mail.send_mail(i_email_to => i_director_list, i_email_subject => 'Monthly Downtime',
                   i_email_body => i_report_txt, i_email_cc => i_manager_list,
                   i_email_extra => 'X-Priority: 1', i_env_list => 'Production,Staging');
 </code>
 
 EXAMPLE 3
 --------------------------------------
 Let's assume you have a file on the database in a directory to which you've been
 granted permissions to read or read/write, and you need to send that file as an
 attachment. You would convert the file to BLOB and pass it in as the attachment.
 <code>
    mail.send_mail(i_email_to => 'dbas@mycompany.com', i_email_subject 'Backup Report',
                   i_email_body => 'See the attached report',
                   i_attach => io.convert_file_to_blob(l_date_prefix||'_rman_bkp.rpt','RPT_DIR'),
                   i_attach_file_nm => l_date_prefix||'_rman_bkp.rpt');
 </code>
 
 EXAMPLE 4
 --------------------------------------
 If you have some BLOB content in memory, or stored in a column somewhere, you just
 pass it directly via the i_attach parameter. But if your content is stored in
 memory or a column as a CLOB, it will need to be converted to BLOB first. And
 because attachments need file names, you'll need to invent a file name for it:
 <code>
    mail.send_mail(i_email_to => 'accountants@mycompany.com', i_email_subject 'Signature Violations!',
                   i_email_body => 'The attached accounts were flagged with signature violations.',
                   i_attach => util.convert_clob_to_blob(i_sig_viol_clob),
                   i_attach_file_nm => 'sig_violations.rtf');
 </code>

%design
 This library was originally written for a lowest-common denominator 8i 
 environment. I called it "poor man's emailing from the database." It only 
 required UTL_FILE. It "sends" emails by writing them to the file system. I 
 would then write a simple cron job on the host system that woke up every 
 minute, checked for new mail files in the email directory, sent them using the 
 mailx utility, and then moved the sent file to an archive directory that 
 would get cleaned out by another cron job whenever it got over a certain size.
 If you still need this simple method of emailing, use mail.write_mail and
 comment out the rest.
 
 Recently, this library was completely redone, to take advantage of UTL_SMTP, 
 UTL_TCP, UTL_HTTP and Java in the database, which can be had from 9i onward. This
 redesign adds the ability to send email directly from within PL/SQL and get
 responses back from the SMTP server. I also synthesized about seven different
 sets of example code found on the web (most of which were too complex or buggy)
 in order to provide the ability to write multi-part emails, emails with text
 or binary attachments, etc.
 
 The best resource was the sample code offered by Oracle at
 http://www.oracle.com/technology/sample_code/tech/pl_sql/htdocs/Utl_Smtp_Sample.html
 
 If you are on 10g, you have the additional option of using UTL_MAIL for the
 implementation of the routines in this library. To use UTL_MAIL you need to
 install it as SYS:
 
 <code>
   CONN sys/password AS SYSDBA
   start $ORACLE_HOME/rdbms/admin/utlmail.sql
   start $ORACLE_HOME/rdbms/admin/prvtmail.plb
 </code>
 
 and then set your SMTP init parameter and bounce the database:
 
 <code>
   CONN sys/password AS SYSDBA
   ALTER SYSTEM SET smtp_out_server='smtp.domain.com' SCOPE=SPFILE;
   SHUTDOWN IMMEDIATE
   STARTUP
 </code>

 You would then refactor the innards of send_mail to use UTL_MAIL instead.

<pre>
Artisan      Date      Comments
============ ========= =========================================================
bcoulam      1997Dec30 Creation
bcoulam      2008May08 Complete rewrite.

</pre>

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
AS 

--------------------------------------------------------------------------------
--                               PUBLIC CURSORS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                                PUBLIC TYPES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                 PUBLIC CONSTANTS, VARIABLES, EXCEPTIONS, ETC.
--------------------------------------------------------------------------------
DEFAULT_EMAIL_TARGETS CONSTANT app_parm.parm_nm%TYPE := 'Default Email Targets';
TCP_TIMEOUT_SECS CONSTANT PLS_INTEGER := 30;
--SMTP_MAILER_ID        CONSTANT VARCHAR2(256) := 'Oracle UTL_SMTP';
JAVA_MAILER_ID        CONSTANT VARCHAR2(256) := 'JavaMail in Oracle';
TARGET_SMTP CONSTANT VARCHAR2(10) := 'SMTP';
TARGET_FILE CONSTANT VARCHAR2(10) := 'File';
TARGET_TABLE CONSTANT VARCHAR2(10) := 'Table';

-- The definitions of SMTP reply codes can be found in RFC 821, 2821 and 1985
-- In general the first digit's meanings are:
--  1 positive (preliminary), 2 positive (completion), 3 positive (intermediate), 
--  4 negative (transient), 5 negative (permanent) 
-- The second digit's meanings are:
--  0 syntax, 1 information, 2 connection, 3 & 4 unspecified, 5 mail system
CONN_OK CONSTANT PLS_INTEGER := 220; -- positive connection response
SMTP_OK CONSTANT PLS_INTEGER := 250; -- positive mail system response

-- A unique string that demarcates boundaries of parts in a multi-part email
-- The string should not appear inside the body of any part of the email.
-- See RFC 2049 for further information on boundaries and multi-part emails.
--BOUNDARY        CONSTANT VARCHAR2(256) := dbms_random.string('X',30);
--FIRST_BOUNDARY  CONSTANT VARCHAR2(80) := '--' || BOUNDARY || str.CRLF;
--LAST_BOUNDARY   CONSTANT VARCHAR2(80) := '--' || BOUNDARY || '--' || str.CRLF;

-- A MIME type that denotes multi-part email (MIME) messages.
--MULTIPART_MIME_TYPE CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary="'|| BOUNDARY || '"';
--MAX_BASE64_LINE_WIDTH CONSTANT PLS_INTEGER   := 76 / 4 * 3;

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
get_targets:
 Returns the current target(s) to which emails are being routed.
------------------------------------------------------------------------------*/
FUNCTION get_targets RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
is_smtp_server_avail
 Function to determine if the SMTP server is available and accepting requests.
 The address of the SMTP server is configured by the application's "SMTP Host" 
 parameter in APP_ENV_PARM.

%design
 Concept of this routine was inspired by Barry Chase's MAIL_TOOLS.query_server.
 
%caveat 
 The innards of this routine assume the SMTP port is 25. If it is anything
 other, change the global constant in the body of this package, or use the
 parameter tables and the PARMS package to table-drive the port per environment.

%warn 
 In my initial tests with this routine, the TCP connection would arbitrarily
 hang. Most of the time this function returned in milliseconds. Sometimes it
 would timeout. I have no idea what is causing that.

%usage
 <code>
 IF (is_smtp_server_avail) THEN
    send_mail(...);
 END IF:
 </code>
 
%return
 TRUE if server could be reached and accepted a HELO, FALSE otherwise.
------------------------------------------------------------------------------*/
FUNCTION is_smtp_server_avail RETURN BOOLEAN;

--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
set_targets:
 Routine meant to temporarily override the default email targets specified by 
 the parameter "Default Email Targets" in APP_ENV_PARM. See send_mail for 
 further info on configuring this parameter.
 
%design 
 If you need to override the targets set by Default Email Targets, you call this
 routine with your desired targets set to TRUE. One call to set_targets at the 
 top of the driving procedure is usually sufficient for the entire session. If,
 in the middle of your code you have a special block that needs to go to a 
 different target than that set for the rest of the session, you may call 
 mail.write_mail or mail.store_mail directly, both of which ignore configured or
 overriden targets.
 
%note
 If "Default Email Targets" isn't configured in APP_ENV_PARM for the environment,
 AND set_targets has not been called, send_email will route all emails only to
 table.

%usage
 <code>
   BEGIN

      mail.set_targets(FALSE,TRUE,TRUE);

      -- OR optionally use named notation, like so:

      mail.set_targets(i_smtp => FALSE, i_table  => TRUE);
      ...
      mail.send_mail(...); -- uses overriden targets when routing email      
      
   END;   
 <code>

%param i_smtp TRUE means email messages will be routed to the SMTP server.
%param i_table TRUE means email messages will be routed to the APP_EMAIL[_DOC] table.
%param i_file TRUE means email messages will be routed to the email file directory.
------------------------------------------------------------------------------*/
PROCEDURE set_targets
(
   i_smtp     IN BOOLEAN DEFAULT FALSE,
   i_table    IN BOOLEAN DEFAULT FALSE,
   i_file     IN BOOLEAN DEFAULT FALSE
);

/**-----------------------------------------------------------------------------
upd_email:
  Will update the status and error message (if any) for a given email ID.
  
  I'm anticipating that some shops will want to build a dedicated emailer, external
  to Oracle, that will read the Not Sent and Error emails in APP_EMAIL and attempt
  to send them. When attempts are successful, the emailer will call this routine
  to update the Status to "Sent". When they are not sent, they should pass in
  "Error" and fill i_smtp_error with as much context about the error as possible.

%param i_email_id The ID from app_email. Assumes it was read earlier.
%param i_new_status Valid values are Not Sent, Sent, Send Pending, and Error.
%param i_smtp_error If i_new_status is Error, make sure to pass in the SMTP 
                    error code and error message so the problem can be researched.
------------------------------------------------------------------------------*/
PROCEDURE upd_email
(
   i_email_id   IN app_email.email_id%TYPE,
   i_new_status IN app_email.sent_status%TYPE,
   i_smtp_error IN app_email.smtp_error%TYPE DEFAULT NULL
);

/**-----------------------------------------------------------------------------
store_mail:
 Records an email record in the APP_EMAIL table (and APP_EMAIL_DOC if there is 
 an attachment).
 
%design
 This is in anticipation of an application that requires lots of 
 email traffic where calling send_mail would be too slow. To increase throughput,
 the idea is that emails would be written to a table in batches. Then a separate
 application -- perhaps a few parallel cron-spawned processes -- could connect 
 to Oracle, read a chunk of emails (marking sent_status as Send Pending to 
 prevent parallel processes from duplicating work), send them with one open SMTP
 connection per process, then mark the emails in app_email as Sent with the 
 timestamp (using upd_email).

 Another use for store_mail is to have a DB-queryable record of all emails sent 
 from the database. If your email traffic is heavy, this could take considerable 
 space. You would then want to design an automated job to periodically archive 
 and purge old email.

%caveat
 store_mail ignores the Default Email Targets parameter, recording the email in
 table only.

%see send_mail for parameter list documentation

%param i_email_id Only used when store_mail is being called by send_mail.
%param i_sent_dt Only used by send_mail after an SMTP error.
%param i_sent_status Only used by send_mail after an SMTP error.
%param i_smtp_error Only used by send_mail after an SMTP error.
------------------------------------------------------------------------------*/
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
);

/**-----------------------------------------------------------------------------
write_mail:
 Writes the email as a file to the directory specified by the Default Email 
 File Directory parameter.
 
%note
 This is the only version of the mail routines that does not accept binary
 attachments.

%caveat
 write_mail ignores the Default Email Targets parameter, writing the email only
 in the file system.

%future
 It could be expanded someday to support attachments using UTL_RAW and such to 
 write the binary data to separate files. The files would have to be related by
 reference within the mail message, and by shared email_id in the file names.
 
 
%see send_mail for parameter list documentation

%param i_email_id Only used when write_mail is being called by send_mail
------------------------------------------------------------------------------*/
PROCEDURE write_mail
(
   i_email_to      IN app_email.email_to%TYPE,
   i_email_subject IN app_email.email_subject%TYPE,
   i_email_body    IN CLOB,
   -- the remaining parameters below are all optional
   i_email_from    IN app_email.email_from%TYPE DEFAULT NULL,
   i_email_replyto IN app_email.email_replyto%TYPE DEFAULT NULL,
   i_email_cc      IN app_email.email_cc %TYPE DEFAULT NULL,
   i_email_bcc     IN app_email.email_bcc%TYPE DEFAULT NULL,
   i_email_extra   IN app_email.email_extra %TYPE DEFAULT NULL,
   i_env_list      IN VARCHAR2 DEFAULT NULL,
   i_email_id      IN app_email.email_id%TYPE DEFAULT NULL
);

/**-----------------------------------------------------------------------------
send_mail:
 Formats and sends an email message using the JavaMail API. May also record the
 email message in a file and the APP_EMAIL[_DOC] table depending on the email
 targets specified by the "Default Email Targets" parameter for a given
 environment.

%note
 Only the first three fields are required. If the From is empty, it will be 
 filled by calling env.get_schema_email_address, which is not a valid email
 address, but does at least let the recipients know where the email came from.

%design
 The syntax for Default Email Targets is 
   
   SMTP=Y|N,Table=Y|N,File=Y|N
   
 If this parameter is not found, emails will only be written to table, not sent
 to SMTP or written to file. This is because we are guessing that if the
 Default Email Targets has not been configured, then other things, like a file
 directory and SMTP server haven't been properly set up yet either, but the
 framework CAN count on the APP_EMAIL table being present.
 
 If the Default Email Targets parameter is found, then it will be parsed and 
 emails will be routed to the specified targets.

%param i_email_to Required. Comma-delimited list of recipients.
%param i_email_subject Required. The standard email Subject header.
%param i_email_body Required. The standard email Body header.
%param i_email_from Optional. Ideally filled with a valid email address. 
%param i_email_replyto Optional. Single or comma-delimited list of reply-to addresses.
%param i_email_cc Optional. Comma-delimited list of carbon-copy recipients.
%param i_email_bcc Optional. Comma-delimited list of blind carbon-copy recipients.
%param i_email_extra: Optional extra smtp headers. These have the form of:
                     "field: value" where field begins with "X-", e.g.
                     X-Priority: 1
                     Most X- header fields depend on the particular email gateway
                     and client(s) used by each company.
%param i_attach Email attachment in binary format. It is anticipated that most
                email attachments, if used at all, will be rich text or Word docs,
                Excel docs, PDF docs and images. If your attachment is textual,
                it can be converted to BLOB fairly easily. If your attachment is
                already a file on the database host file system, read and convert
                it to BLOB using io.convert_file_to_blob. If your attachment is
                a CLOB column or in-memory variable, convert it to BLOB using
                util.convert_clob_to_blob;
%param i_attach_file_nm Name of the attachment which the user's email reader will
                        see and use, e.g. "monthly_report.pdf". Correct file 
                        extensions are very important as we transparently determine
                        the MIME type of the attachment using the extension (%see
                        util.get_mime_type for the list and algorithm).
%param i_env_list Optional comma-delimited list of valid environments (see 
                  APP_ENV.env_nm) where this email should be processed. If this 
                  is NULL or empty, the email will be processed on all environments.
                  If a list of environments is given, the email will only be 
                  processed if this session is running on one of the specified
                  environments.
                  
                  For example, if a caller were to pass:
                    i_env_list => 'Production, Staging'
                  send_mail would determine if the current database it is on is
                  a production or staging DB (using APP_ENV_VW) and ignore the
                  email altogether if it were running on dev, test, build, etc.

------------------------------------------------------------------------------*/
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
   i_env_list IN VARCHAR2 DEFAULT NULL
);














--------------------------------------------------------------------------------
-- The following half of the this package is the SMTP implementation adapted from
-- http://www.oracle.com/technology/sample_code/tech/pl_sql/htdocs/Utl_Smtp_Sample.html
-- Comment this half back in if the JavaMail interface above (send_mail) is not
-- working or if you have a policy about not using Java in the database. Go to
-- the URL above for some sample code on how to use these SMTP APIs to send
-- all sorts of complex emails, including those in Unicode, multiple attachments, etc.
--------------------------------------------------------------------------------
--/**-----------------------------------------------------------------------------
--send
-- A simple API for sending a plain text email message with no attachments.
--
--%design
-- The format of an email address is one of these:
--  someone@mycompany.com
--  "Someone at some domain" <someone@mycompany.com>
--  Someone at some domain <someone@mycompany.com>
--
-- The recipients is a list of email addresses  separated by either a "," or a ";"
-- 
--%usage
-- <code>
--    mail.send('automated_process@host.mycompany.com','joedba@mycompany.com',
--              'Process Terminated Abnormally','Please check APP_LOG for error context');
-- </code>
-- 
--%param i_sender  The "From" sender's address.
--%param i_recipients  Delimited list of email "To" recipients
--%param i_subject  Email "Subject" line.
--%param i_message Email "Body"
--------------------------------------------------------------------------------*/
--PROCEDURE send
--(
--  i_sender     IN VARCHAR2,
--  i_recipients IN VARCHAR2,
--  i_subject    IN VARCHAR2,
--  i_msg        IN VARCHAR2
--);
--
--/**-----------------------------------------------------------------------------
--begin_mail
-- Extended email API to send email in HTML or plain text with no size limit.
--
--%usage
-- First, begin the email by begin_mail(). Then, call write_text() repeatedly to
-- send email in ASCII piece-by-piece. Or, call write_mb_text() to send email in 
-- non-ASCII or multi-byte character set. End the email with end_mail().
--
-- <code>
--   DECLARE
--      l_conn utl_smtp.connection;
--   BEGIN
--      l_conn := mail.begin_mail(i_sender     => 'Me <joedba@mycompany.com>',
--                                i_recipients => 'Someone <someone@mycompany.com>',
--                                i_subject    => 'HTML E-mail Test',
--                                i_mime_type  => 'text/html');
--   
--      demo_mail.write_text(io_conn => l_conn,
--                           i_msg   => '<h1>Hi! This is a <i>test</i>.</h1>');
--   
--      demo_mail.end_mail(io_conn => l_conn);
--   
--   END;
-- </code>
-- 
--%param i_sender  The "From" sender's address.
--%param i_recipients  Delimited list of email "To" recipients
--%param i_subject  Email "Subject" line.
--%param i_mime_type  MIME type as determined by the caller.
--%param i_priority  Integer from 1 to 5. Nobody sets priority low, so you are 
--                   probably interested in 1 or 2, which most email clients will
--                   flag or highlite in red as High Priority.
--------------------------------------------------------------------------------*/
--FUNCTION begin_mail
--(
--   i_sender     IN VARCHAR2,
--   i_recipients IN VARCHAR2,
--   i_subject    IN VARCHAR2,
--   i_mime_type  IN VARCHAR2 DEFAULT 'text/plain',
--   i_priority   IN PLS_INTEGER DEFAULT NULL
--) RETURN utl_smtp.connection;
--
--/**-----------------------------------------------------------------------------
--write_text
-- Write email body in ASCII to an email started by a prior call to begin_mail.
--
--%param i_conn  Handle to the SMTP server connection.
--%param i_message  Plain text email body.
--------------------------------------------------------------------------------*/
--PROCEDURE write_text
--(
--   io_conn    IN OUT NOCOPY utl_smtp.connection,
--   i_msg  IN VARCHAR2
--);
--
--/**-----------------------------------------------------------------------------
--write_mb_text
-- Write email body in non-ASCII (including multi-byte) to an email started by a
-- prior call to begin_mail. The email body will be sent in the database character 
-- set.
--
--%usage
-- <code>
--REM Send an email in Chinese (big5). This needs to be executed in a database
--REM with ZHT16BIG5 character set.
--
--DECLARE
--  l_conn utl_smtp.connection;
--BEGIN
--  conn := demo_mail.begin_mail(
--    i_sender     => 'Me <me@mycompany.com>',
--    i_recipients => 'Someone <someone@mycompany.com>',
--    i_subject    => 'Chinese Email Test',
--    i_mime_type  => 'text/plain; charset=big5');
--
--  demo_mail.write_mb_text(
--    io_conn    => l_conn,
--    i_msg => 'Chinese email example - 中文電子郵件例子' || utl_tcp.CRLF);
--
--  demo_mail.end_mail( conn => conn );
--END;
-- </code>
-- 
--%param i_conn  Handle to the SMTP server connection.
--%param i_msg  Wide-character email body (UTF-8, etc.)
--------------------------------------------------------------------------------*/
--PROCEDURE write_mb_text
--(
--   io_conn    IN OUT NOCOPY utl_smtp.connection,
--   i_msg  IN VARCHAR2
--);
--
--/**-----------------------------------------------------------------------------
--write_raw
-- Write email body in binary to an email started by a prior call to begin_mail.
-- 
--%usage
-- <code>
-- </code>
-- 
--%param i_conn  Handle to the SMTP server connection.
--%param i_msg  Binary email body.
--------------------------------------------------------------------------------*/  
--PROCEDURE write_raw
--(
--   io_conn    IN OUT NOCOPY utl_smtp.connection,
--   i_msg  IN RAW
--);
--
--/**-----------------------------------------------------------------------------
--attach_text
-- Attach a single text attachment to an email started by a prior call to 
-- begin_email.
--
--%caveat
-- This routine is limited by the PL/SQL restriction of 32K for VARCHAR2 parameters.
-- If you need to attach text larger than 32K, use begin_attachment, the write* 
-- routines in a loop, and end_attachment instead.
-- 
--%note
-- Be sure to begin the whole email with begin_mail, passing in "multipart/mixed" 
-- as the MIME format.
-- 
--%usage
-- Demo of attaching both ASCII and binary email attachments.
-- <code>
--DECLARE
--   l_conn    utl_smtp.connection;
--   l_req     utl_http.l_req;
--   l_resp      utl_http.resp;
--   l_rawdata RAW(200);
--BEGIN
--   l_conn := demo_mail.begin_mail(i_sender     => 'Me <me@mycompany.com>',
--                                  i_recipients => 'Someone <someone@mycompany.com>',
--                                  i_subject    => 'Attachment Test',
--                                  i_mime_type  => demo_mail.multipart_mime_type);
--
--   demo_mail.attach_text(io_conn     => CONN,
--                         i_data      => '<h1>Hi! This is a test.</h1>',
--                         i_mime_type => 'text/html');
--
--   demo_mail.begin_attachment(io_conn        => CONN,
--                              i_mime_type    => 'image/gif',
--                              i_inline       => TRUE,
--                              i_filename     => 'image.gif',
--                              i_transfer_enc => 'base64');
--
--   -- In writing Base-64 encoded text following the MIME format below,
--   -- the MIME format requires that a long piece of l_rawdata must be splitted
--   -- into multiple lines and each line of encoded l_rawdata cannot exceed
--   -- 80 characters, including the new-line characters. Also, when
--   -- splitting the original l_rawdata into pieces, the length of each chunk
--   -- of l_rawdata before encoding must be a multiple of 3, except for the
--   -- last chunk. The constant demo_mail.MAX_BASE64_LINE_WIDTH
--   -- (76 / 4 * 3 = 57) is the maximum length (in bytes) of each chunk
--   -- of l_rawdata before encoding.
--
--   l_req := utl_http.begin_request('http://www.mycompany.com/image.gif');
--   resp  := utl_http.get_response(l_req);
--
--   BEGIN
--      LOOP
--         utl_http.read_raw(l_resp, l_rawdata, demo_mail.max_base64_line_width);
--         demo_mail.write_raw(io_conn => CONN,
--                             i_msg   => utl_encode.base64_encode(l_rawdata));
--      END LOOP;
--   EXCEPTION
--      WHEN utl_http.end_of_body THEN
--         utl_http.end_response(l_resp);
--   END;
--   demo_mail.end_attachment(io_conn => l_conn);
--
--   demo_mail.attach_text(io_conn     => l_conn,
--                         i_data      => '<h1>This is a HTML report.</h1>',
--                         i_mime_type => 'text/html',
--                         i_inline    => FALSE,
--                         i_filename  => 'report.htm',
--                         i_last      => TRUE);
--
--   demo_mail.end_mail(CONN => CONN);
--
--END;
-- </code>
-- 
--%param i_conn  Handle to the SMTP server connection.
--%param i_data  Character data as the body of the attachment.
--%param i_mime_type  MIME type of the text-based attachment.
--%param i_inline  Whether to include the attachment inline or not.
--%param i_filename  Name of the attachment, so it may be referenced by the email
--                   client and saved to disk.
--%param i_last  Whether or not this is the last attachment that can be expected
--               for the email.
--------------------------------------------------------------------------------*/
--PROCEDURE attach_text
--(
--   io_conn     IN OUT NOCOPY utl_smtp.connection,
--   i_data      IN VARCHAR2,
--   i_mime_type IN VARCHAR2 DEFAULT 'text/plain',
--   i_inline    IN BOOLEAN DEFAULT TRUE,
--   i_filename  IN VARCHAR2 DEFAULT NULL,
--   i_last      IN BOOLEAN DEFAULT FALSE
--);
--
--/**-----------------------------------------------------------------------------
--attach_base64
-- Attach a single binary attachment to an email started by a prior call to 
-- begin_email. The attachment will be encoded in Base-64 encoding format. The 
-- MIME type defaults to the less-than-useful "application/octet-stream" unless 
-- you specify otherwise.
--
--%caveat
-- This routine is limited by the PL/SQL restriction of 32K for RAW parameters.
-- If you need to attach binary data longer than 32K, use begin_attachment, the 
-- write* routines in a loop, and end_attachment instead.
-- 
--%usage
-- %see attach_text
-- 
--%param i_conn  Handle to the SMTP server connection.
--%param i_data  Binary data as the body of the attachment.
--%param i_mime_type  MIME type of the binary attachment.
--%param i_inline  Whether to include the attachment inline or not.
--%param i_filename  Name of the attachment, so it may be referenced by the email
--                   client and saved to disk.
--%param i_last  Whether or not this is the last attachment that can be expected
--               for the email.
--------------------------------------------------------------------------------*/  
--PROCEDURE attach_base64
--(
--   io_conn     IN OUT NOCOPY utl_smtp.connection,
--   i_data      IN RAW,
--   i_mime_type IN VARCHAR2 DEFAULT 'application/octet-stream',
--   i_inline    IN BOOLEAN DEFAULT TRUE,
--   i_filename  IN VARCHAR2 DEFAULT NULL,
--   i_last      IN BOOLEAN DEFAULT FALSE
--);
--  
--/**-----------------------------------------------------------------------------
--begin_attachment
-- Send an attachment with no size limit.
--
--%design 
-- First, begin the attachment with begin_attachment(). Then, call write_text 
-- repeatedly to send the attachment piece-by-piece. If the attachment is text-
-- based but in non-ASCII or multi-byte character set, use write_mb_text() instead.
-- To send binary attachment, the binary content should first be encoded in 
-- Base-64 encoding format using the demo package for 8i, or the native one in 9i
-- (UTL_ENCODE). End the attachment with end_attachment.
--
--%usage
-- %see attach_text
-- 
--%param i_conn  Handle to the SMTP server connection.
--%param i_mime_type  MIME type of the text or binary attachment.
--%param i_inline  Whether to include the attachment inline or not.
--%param i_filename  Name of the attachment, so it may be referenced by the email
--                   client and saved to disk.
--%param i_last  Whether or not this is the last attachment that can be expected
--               for the email.
--------------------------------------------------------------------------------*/
--PROCEDURE begin_attachment
--(
--   io_conn        IN OUT NOCOPY utl_smtp.connection,
--   i_mime_type    IN VARCHAR2 DEFAULT 'text/plain',
--   i_inline       IN BOOLEAN DEFAULT TRUE,
--   i_filename     IN VARCHAR2 DEFAULT NULL,
--   i_transfer_enc IN VARCHAR2 DEFAULT NULL
--);
--  
--/**-----------------------------------------------------------------------------
--end_attachment
-- Caps off the attachment begun by begin_attachment().
--
--%param i_conn Handle to the SMTP server connection.
--%param i_last  Whether or not this is the last attachment that can be expected
--               for the email.
--------------------------------------------------------------------------------*/
--PROCEDURE end_attachment
--(
--   io_conn IN OUT NOCOPY utl_smtp.connection,
--   i_last  IN BOOLEAN DEFAULT FALSE
--);
--  
--/**-----------------------------------------------------------------------------
--end_mail
-- Caps off the entire email begun by calling begin_mail().
--
--%param i_conn Handle to the SMTP server connection.
--------------------------------------------------------------------------------*/
--PROCEDURE end_mail(io_conn IN OUT NOCOPY utl_smtp.connection);
--
--/**-----------------------------------------------------------------------------
--begin_session
-- Extended email API to send multiple emails in a session for better performance.
--
--%usage 
-- First, begin an email session with begin_session.
-- Then, begin each email within a session by calling begin_mail_in_session 
-- instead of begin_mail.
-- End each email with end_mail_in_session instead of end_mail.
-- End the email session by calling end_session.
--
--%return
-- Handle to the SMTP server.
--------------------------------------------------------------------------------*/
--FUNCTION begin_session RETURN utl_smtp.connection;
--  
--/**-----------------------------------------------------------------------------
--begin_mail_in_session
-- Begin an email within an open session (pointed to by the connection handle 
-- returned by begin_session).
--
--%usage
-- %see begin_session for the list of steps.
--
--%param io_conn Handle to the SMTP server connection.
--%param i_sender  The "From" sender's address.
--%param i_recipients  Delimited list of email "To" recipients
--%param i_subject  Email "Subject" line.
--%param i_mime_type  MIME type of the text or binary attachment.
--%param i_priority  Integer from 1 to 5. Nobody sets priority low, so you are 
--                   probably interested in 1 or 2, which most email clients will
--                   flag or highlite in red as High Priority.
--------------------------------------------------------------------------------*/
--PROCEDURE begin_mail_in_session
--(
--   io_conn      IN OUT NOCOPY utl_smtp.connection,
--   i_sender     IN VARCHAR2,
--   i_recipients IN VARCHAR2,
--   i_subject    IN VARCHAR2,
--   i_mime_type  IN VARCHAR2 DEFAULT 'text/plain',
--   i_priority   IN PLS_INTEGER DEFAULT NULL
--);
--  
--/**-----------------------------------------------------------------------------
--end_mail_in_session
-- End an email started with begin_mail_in_session.
--
--%param i_conn Handle to the SMTP server connection.
--------------------------------------------------------------------------------*/
--PROCEDURE end_mail_in_session(io_conn IN OUT NOCOPY utl_smtp.connection);
--  
--/**-----------------------------------------------------------------------------
--end_mail_in_session
-- End an email session begun with begin_session.
--
--%param i_conn Handle to the SMTP server connection.
--------------------------------------------------------------------------------*/
--PROCEDURE end_session(io_conn IN OUT NOCOPY utl_smtp.connection);


END mail;
/
