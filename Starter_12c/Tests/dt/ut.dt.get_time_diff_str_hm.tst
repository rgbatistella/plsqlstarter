PL/SQL Developer Test script 3.0
6
begin
  -- Call the function
  :result := dt.get_time_diff_str(i_old_dtm => :i_old_dtm,
                                  i_curr_dtm => :i_curr_dtm,
                                  i_tm_uom => :i_tm_uom);
end;
4
result
1
﻿
5
i_old_dtm
1
2008Jul27
12
i_curr_dtm
1
2008Jul29 03:12:00
12
i_tm_uom
1
﻿hm
5
0
