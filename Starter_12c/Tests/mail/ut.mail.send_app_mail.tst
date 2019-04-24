PL/SQL Developer Test script 3.0
10
begin
  -- Call the procedure
  env.set_app_cd('CORE');
  logs.set_dbg(TRUE);
  logs.set_targets(TRUE,TRUE,FALSE);
  mail.send_mail(i_email_to => :i_email_to,
                 i_email_subject => :i_email_subject,
                 i_email_body => :i_email_body,
                 i_email_from => :i_email_from);
end;
4
i_email_to
1
﻿bcoulam@yahoo.com
5
i_email_subject
1
﻿Test Message from MAIL package
5
i_email_body
4
﻿This is the test message,
with a new line and everythang!

bc
5
i_email_from
1
﻿core@my12c.com
5
0
