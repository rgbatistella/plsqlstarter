PL/SQL Developer Test script 3.0
36
DECLARE
   l_large_msg CLOB;
   l_doc BLOB;

BEGIN
   mail.set_targets(i_smtp => TRUE, i_table => TRUE, i_file => TRUE);
   logs.set_dbg('ON');
   
   dbms_lob.createtemporary(l_large_msg, TRUE);
   WHILE dbms_lob.getlength(l_large_msg) < io.MAX_FILE_LINE_LEN LOOP
      l_large_msg := l_large_msg||'According to the USGS,[9] the earthquake occurred as the result of motion on a northeast striking reverse fault or thrust fault on the northwestern margin of the Sichuan Basin. The earthquake''s epicenter and focal-mechanism are consistent with it having occurred as the result of movement on the Longmenshan fault or a tectonically related fault. The earthquake reflects tectonic stresses resulting from the convergence of crustal material slowly moving from the high Tibetan Plateau, to the west, against strong crust underlying the Sichuan Basin and southeastern China.

On a continental scale, the seismicity of central and eastern Asia is a result of northward convergence of the Indian Plate against the Eurasian Plate with a velocity of about 50 mm/y. The convergence of the two plates is broadly accommodated by the uplift of the Asian highlands and by the motion of crustal material to the east away from the uplifted Tibetan Plateau. The northwestern margin of the Sichuan Basin has previously experienced destructive earthquakes. The magnitude 7.5 earthquake of August 25, 1933, killed more than 9,300 people.

';
   END LOOP;
   dbms_output.put_line('Length of l_large_msg is '||dbms_lob.getlength(l_large_msg)); 
   
   l_doc := util.convert_clob_to_blob(l_large_msg);
   
   -- Call the procedure
   mail.send_mail(i_email_to => :i_email_to,
                 i_email_subject => :i_email_subject,
                 i_email_body => :i_email_body,
                 i_email_from => :i_email_from,
                 i_email_replyto => :i_email_replyto,
                 i_email_cc => :i_email_cc,
                 i_email_bcc => :i_email_bcc,
                 i_email_extra => :i_email_extra,
                 i_attach => l_doc,
                 i_attach_file_nm => 'USGS_Earthquake_Report.txt'
                 );

   mail.set_targets(i_smtp => TRUE, i_table => TRUE, i_file => FALSE);
   logs.set_dbg('OFF');
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
﻿This is a test of the second half of send_omail.
5
i_email_from
1
﻿"Core System" <core@bogus.com>
5
i_email_replyto
0
5
i_email_cc
0
5
i_email_bcc
0
5
i_email_extra
0
5
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
