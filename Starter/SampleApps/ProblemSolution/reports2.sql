DECLARE
   l_app_id app.app_id%TYPE;
BEGIN
   SELECT env.get_app_id INTO l_app_id FROM dual;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      env.set_app_cd('PSOL');
END;
/

INSERT INTO app_msg
VALUES (
 app_msg_seq.nextval
,env.get_app_id('PSOL')
,'Missing Parameter'
,'The call to @1@ was missing a value for parameter @2@. Please correct and re-try.'
,NULL
,NULL
);
COMMIT;

CREATE OR REPLACE PACKAGE reports
AS
rpt_div_line CONSTANT VARCHAR2(80) := RPAD('*',80,'*');
-- Pass an email address if on non-Prod
PROCEDURE print_and_send_ps(i_email_addr IN VARCHAR2 DEFAULT NULL);
END reports;
/

CREATE OR REPLACE PACKAGE BODY reports
AS

PROCEDURE print_and_send_ps
(
  i_email_addr IN VARCHAR2 DEFAULT NULL
)
IS

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

   l_lines    typ.tas_maxvc2;
   l_email    CLOB := EMPTY_CLOB();
   l_filename VARCHAR2(128) := 'rpt_probsol_'||TO_CHAR(SYSDATE,'YYYYMMDD')||'.txt';
   l_loop_idx INTEGER := 0;
   
BEGIN
   excp.assert((env.get_env_nm <> 'ProbSol Prod' AND i_email_addr IS NOT NULL)
               OR env.get_env_nm = 'ProbSol Prod',
               msgs.fill_msg('Missing Parameter', env.who_am_i, 'i_email_addr'),
               TRUE);

   timer.startme('read_db_write_file');
   
   logs.dbg('Checking for file '||l_filename);
   IF (io.file_exists(l_filename)) THEN
      logs.dbg('Deleting file '||l_filename);
      io.delete_file(l_filename);
   END IF; 
   
   env.tag(i_module => 'REPORTS.print_and_send_ps', i_action => 'Open cur_read_ps_db cursor', i_info => '');
   
   logs.dbg('Reading and storing all problem/solution rows');
   FOR l_rec IN cur_read_ps_db LOOP
   
      DECLARE
         PROCEDURE handle_line(i_line IN VARCHAR2) IS
         BEGIN
            l_lines(l_lines.COUNT+1) := i_line;
            l_email := l_email || i_line || CHR(10);
         END handle_line;
      BEGIN
         l_loop_idx := l_loop_idx + 1; -- placed to demo variable watches and conditional loops
         
         IF (l_lines.COUNT = 0) THEN -- Add header if nothing in report yet
            handle_line(str.ctr(RPT_DIV_LINE));
            handle_line(str.ctr('Printout of the Problem/Solution Database'));
            handle_line(str.ctr(TO_CHAR(SYSDATE, 'YYYY Month DD')));
            handle_line(str.ctr(RPT_DIV_LINE)
                        ||CHR(10));
         END IF;
         handle_line('Type [' || l_rec.prob_src_nm || '] Key [' ||
                     l_rec.prob_key || '] Error [' || l_rec.prob_key_txt || ']');
         handle_line('Comments:');
         handle_line(CHR(9) || l_rec.prob_notes);
         handle_line('Solution #'||l_rec.seq||':');
         handle_line(CHR(9) || l_rec.sol_notes || CHR(10));
         handle_line('--------------------------------------------');

      END;   

   END LOOP;
   env.untag();   
   
   logs.dbg('Writing '||l_lines.COUNT||' lines to file '||l_filename);
   io.write_lines(i_msgs => l_lines, i_file_nm => l_filename);
   
   timer.stopme('read_db_write_file');   
   logs.info('Reading DB and writing file took '||timer.elapsed('read_db_write_file')||' seconds.');
   
   timer.startme('write_email');
   logs.dbg('Sending report to director if in Production, otherwise to given email address');
   mail.send_mail(i_email_to => i_email_addr,
                  i_email_subject => l_filename,
                  i_email_body => l_email,
                  i_env_list => 'ProbSol Dev, ProbSol Test');
   mail.send_mail(i_email_to => 'bcoulam@boguscompany.com',
                  i_email_subject => l_filename,
                  i_email_body => l_email,
                  i_env_list => 'ProbSol Prod');
   timer.stopme('write_email');

   logs.info('Writing email took '||timer.elapsed('write_email')||' seconds.');
   
END print_and_send_ps;

END reports;
/
