PL/SQL Developer Test script 3.0
12
declare
  -- Boolean parameters are translated from/to integers: 
  -- 0/1/null <--> false/true/null 
  i_expr boolean := sys.diutil.int_to_bool(:i_expr);
  i_raise_excp boolean := sys.diutil.int_to_bool(:i_raise_excp);
begin
  -- Call the procedure
  excp.assert(i_expr => i_expr,
              i_msg => :i_msg,
              i_routine_nm => :i_routine_nm,
              i_raise_excp => i_raise_excp);
end;
4
i_expr
1
0
3
i_msg
1
﻿There is an error from prior process. Cannot proceed.
5
i_routine_nm
1
﻿bogus
5
i_raise_excp
1
1
3
0
