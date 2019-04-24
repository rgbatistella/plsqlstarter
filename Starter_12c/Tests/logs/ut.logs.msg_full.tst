PL/SQL Developer Test script 3.0
12
declare
  -- Boolean parameters are translated from/to integers: 
  -- 0/1/null <--> false/true/null 
  i_reraise boolean := sys.diutil.int_to_bool(:i_reraise);
begin
  -- Call the procedure
  logs.msg(i_msg_cd => :i_msg_cd,
           i_sev_cd => :i_sev_cd,
           i_msg => :i_msg,
           i_routine_nm => :i_routine_nm,
           i_reraise => i_reraise);
end;
5
i_msg_cd
1
﻿Ad-Hoc Msg
5
i_sev_cd
1
﻿ERROR
5
i_msg
1
﻿This is a bogus ERROR message. Pay me no mind!
5
i_routine_nm
1
﻿logs.msg
5
i_reraise
1
0
3
0
