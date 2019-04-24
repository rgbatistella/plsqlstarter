PL/SQL Developer Test script 3.0
22
DECLARE
   l_large_msg CLOB;
BEGIN
   logs.set_dbg('ON');
   dbms_lob.createtemporary(l_large_msg, TRUE);
   WHILE dbms_lob.getlength(l_large_msg) < io.MAX_FILE_LINE_LEN LOOP
      l_large_msg := l_large_msg||'According to the USGS,[9] the earthquake occurred as the result of motion on a northeast striking reverse fault or thrust fault on the northwestern margin of the Sichuan Basin. The earthquake''s epicenter and focal-mechanism are consistent with it having occurred as the result of movement on the Longmenshan fault or a tectonically related fault. The earthquake reflects tectonic stresses resulting from the convergence of crustal material slowly moving from the high Tibetan Plateau, to the west, against strong crust underlying the Sichuan Basin and southeastern China.

On a continental scale, the seismicity of central and eastern Asia is a result of northward convergence of the Indian Plate against the Eurasian Plate with a velocity of about 50 mm/y. The convergence of the two plates is broadly accommodated by the uplift of the Asian highlands and by the motion of crustal material to the east away from the uplifted Tibetan Plateau. The northwestern margin of the Sichuan Basin has previously experienced destructive earthquakes. The magnitude 7.5 earthquake of August 25, 1933, killed more than 9,300 people.

';
   END LOOP;
   dbms_output.put_line('Length of l_large_msg is '||dbms_lob.getlength(l_large_msg)); 
   
  -- Call the procedure
  mail.send_mail(i_email_to => :i_email_to,
                 i_email_subject => :i_email_subject,
                 i_email_body => l_large_msg,
                 i_email_from => :i_email_from,
                 i_attach => :i_attach);
   logs.set_dbg('OFF');
end;
11
i_email_to
1
﻿"Bill" <bcoulam@yahoo.com>
5
i_email_subject
1
﻿Test email from the DB
5
i_email_body
1
﻿This is a simple test of a message > 32K. Should see data in app_email.long_body, as well as truncated version with pointer in app_email.email_body.
-5
i_email_from
1
﻿sender@bogus.com
5
i_email_replyto
1
﻿sender@bogus.com
-5
i_email_cc
0
-5
i_email_bcc
0
-5
i_email_extra
1
﻿X-Priority: 1
-5
i_attach
1
<BLOB>
113
i_attach_file_nm
0
-5
i_env_list
0
-5
0
