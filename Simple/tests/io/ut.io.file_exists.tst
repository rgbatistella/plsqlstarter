PL/SQL Developer Test script 3.0
17
declare
  -- Boolean parameters are translated from/to integers: 
  -- 0/1/null <--> false/true/null 
  result boolean;
begin

  io.write_line(i_msg => :i_msg,
                i_file_nm => :i_file_nm,
                i_file_dir => :i_file_dir,
                i_mode => :i_mode);

  result := io.file_exists(i_file_nm => :i_file_nm,
                           i_file_dir => :i_file_dir);

  -- Convert false/true/null to 0/1/null 
  :result := sys.diutil.bool_to_int(result);
end;
5
result
1
1
3
i_file_nm
1
﻿ut_file_exists.txt
5
i_file_dir
1
﻿CORE_DIR
5
i_msg
1
﻿This is my unit test message. Do not touch your dial. This is only a test. Please stand by...
5
i_mode
1
﻿w
5
0
