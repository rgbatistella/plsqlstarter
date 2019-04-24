PL/SQL Developer Test script 3.0
17
DECLARE
   l_doc  BLOB;
   l_file VARCHAR2(50);
   l_str     app_parm_vw.parm_value%TYPE;
BEGIN
   logs.set_dbg(TRUE);
   mail.set_targets(i_smtp => TRUE, i_table => TRUE, i_file => TRUE);
   env.init_client_ctx(i_client_id => 'bcoulam', i_app_cd => 'CORE');
   l_str := parm.get_val('Default Email Targets');
   dbms_output.put_line(l_str);

   mail.send_mail(i_email_to       => :i_email_to,
                  i_email_subject  => :i_email_subject,
                  i_email_body     => :i_email_body,
                  i_email_from     => :i_email_from);
   mail.set_targets(i_smtp => TRUE, i_table => TRUE, i_file => FALSE);
END;
11
i_email_to
1
﻿bcoulam@yahoo.com
5
i_email_subject
1
﻿A test
5
i_email_body
1
﻿This is a simple test of send_mail, store_mail, write_mail, send_omail and the OraMail java class.
5
i_email_from
1
﻿"Core System" <core@bogus.com>
5
i_email_replyto
0
-5
i_email_cc
0
-5
i_email_bcc
0
-5
i_email_extra
0
-5
i_attach
1
<BLOB>
-113
i_attach_file_nm
0
-5
i_env_list
0
-5
0
