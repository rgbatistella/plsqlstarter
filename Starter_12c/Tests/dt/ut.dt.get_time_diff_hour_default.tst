PL/SQL Developer Test script 3.0
6
begin
  -- Call the function
  :result := dt.get_time_diff(i_old_dtm => SYSDATE - 1.3,
                              i_curr_dtm => :i_curr_dtm,
                              i_tm_uom => :i_tm_uom);
end;
4
result
1
31.2
4
i_old_dtm
0
-12
i_curr_dtm
0
12
i_tm_uom
1
﻿hour
5
0
