PL/SQL Developer Test script 3.0
14
BEGIN
   DELETE FROM app_msg WHERE msg_id = 101;
   
   INSERT INTO app_msg (MSG_ID, APP_ID, MSG_CD, MSG, MSG_DESCR)
   VALUES (101, 1, 'Logical Lock Held', 'Lock on @1@ already held by @1@. Try again in @3@ minutes.', 'Logical lock message.');
   
  -- Call the function
  :result := msgs.fill_msg(i_msg_cd => :i_msg_cd,
                           i_field1 => :i_field1,
                           i_field2 => :i_field2,
                           i_field3 => :i_field3,
                           i_field4 => :i_field4,
                           i_field5 => :i_field5);
end;
7
result
0
5
i_msg_cd
1
﻿Logical Lock Held
5
i_field1
1
﻿Bogus Lock
5
i_field2
1
﻿Fake App
5
i_field3
1
﻿5
5
i_field4
0
5
i_field5
0
5
1
ias_fill(1)
