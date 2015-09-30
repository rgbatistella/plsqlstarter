PL/SQL Developer Test script 3.0
6
begin
  -- Call the procedure
  logs.set_log_dir(i_file_dir => :i_file_dir);
  
  :result := logs.get_log_dir;
end;
2
i_file_dir
1
﻿CORE_DIR
5
result
1
﻿
5
0
