PL/SQL Developer Test script 3.0
6
begin
  logs.set_dbg('Y');
  
  logs.dbg(i_msg => :i_msg,
           i_routine_nm => :i_routine_nm);
end;
2
i_msg
1
﻿This is a great way to comment code, thus documenting and providing contextual debugging at the same time.
5
i_routine_nm
1
﻿logs.dbg test
5
0
