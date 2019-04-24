PL/SQL Developer Test script 3.0
14
declare
  -- Boolean parameters are translated from/to integers: 
  -- 0/1/null <--> false/true/null 
  i_stdout boolean := sys.diutil.int_to_bool(:i_stdout);
  i_table boolean := sys.diutil.int_to_bool(:i_table);
  i_file boolean := sys.diutil.int_to_bool(:i_file);
begin
  -- Call the procedure
  logs.set_targets(i_stdout => i_stdout,
                   i_table => i_table,
                   i_file => i_file);
                   
  :v_result := logs.get_targets;                
end;
4
i_stdout
1
1
3
i_table
1
1
3
i_file
1
1
3
v_result
1
﻿
5
0
