PL/SQL Developer Test script 3.0
6
begin
  -- Call the procedure
  logs.set_log_nm(i_file_nm => :i_file_nm);
  
  :result := logs.get_log_nm;
end;
2
i_file_nm
1
﻿my_logfile.log
5
result
1
﻿
5
0
