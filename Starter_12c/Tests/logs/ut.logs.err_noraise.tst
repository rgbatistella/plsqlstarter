PL/SQL Developer Test script 3.0
10
declare
  -- Boolean parameters are translated from/to integers: 
  -- 0/1/null <--> false/true/null 
  i_reraise boolean := sys.diutil.int_to_bool(:i_reraise);
begin
  -- Call the procedure
  logs.err(i_msg => :i_msg,
           i_routine_nm => :i_routine_nm,
           i_reraise => i_reraise);
end;
3
i_msg
1
﻿An error message to pass to logs.err!
5
i_routine_nm
1
﻿logs.err test
5
i_reraise
1
0
3
0
