PL/SQL Developer Test script 3.0
13
declare
  -- Boolean parameters are translated from/to integers: 
  -- 0/1/null <--> false/true/null 
  i_reraise boolean := sys.diutil.int_to_bool(:i_reraise);
begin
  -- Call the procedure
  RAISE DUP_VAL_ON_INDEX;

EXCEPTION
WHEN OTHERS THEN
  logs.err(i_routine_nm => :i_routine_nm,
           i_reraise => i_reraise);
end;
2
i_routine_nm
1
﻿logs.err test
5
i_reraise
1
1
3
0
