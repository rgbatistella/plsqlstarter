PL/SQL Developer Test script 3.0
6
begin
  -- Call the function
  :result := dt.get_time_diff_str(i_tm_uom => :i_tm_uom,
                                  i_old_dtm => :i_old_dtm,
                                  i_curr_dtm => :i_curr_dtm);
end;
4
result
1
﻿
5
i_tm_uom
1
﻿hour
5
i_old_dtm
1
2008Mar09 01:00:00
12
i_curr_dtm
1
2008Mar10
12
0
