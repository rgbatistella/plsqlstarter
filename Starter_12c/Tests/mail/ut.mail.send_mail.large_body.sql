SET SERVEROUTPUT ON SIZE 1000000
DECLARE

   CURSOR cur_sel IS
      SELECT object_type||'['||object_name||'] is '||status||str.LF AS seltext
      FROM user_objects;

   lc_email  CLOB;
BEGIN

   env.init_client_ctx(i_client_id => 'bcoulam', i_app_cd => 'CORE');
   logs.set_dbg(TRUE);

   dbms_lob.createtemporary(lc_email, TRUE);
   dbms_lob.OPEN(lc_email, dbms_lob.lob_readwrite);

   FOR lr IN cur_sel LOOP
      dbms_lob.APPEND(lc_email, lr.seltext);
   END LOOP;

   mail.send_mail(i_email_to      => 'bcoulam@yahoo.com',
                  i_email_subject => 'Test of sending actual CLOB',
                  i_email_body    => lc_email);

   dbms_lob.CLOSE(lc_email);
   dbms_lob.freetemporary(lc_email);
END;
/
