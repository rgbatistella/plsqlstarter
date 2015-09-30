PL/SQL Developer Test script 3.0
6
begin
  -- Call the function
  :result := dt.get_time_diff(i_old_dtm => :i_old_dtm,
                              i_curr_dtm => :i_curr_dtm,
                              i_tm_uom => :i_tm_uom);
end;
4
result
1
264
4
i_old_dtm
1
2008Jul16
12
i_curr_dtm
1
2008Jul27
12
i_tm_uom
1
﻿hour
5
0
