PL/SQL Developer Test script 3.0
6
begin
  -- Call the procedure
  io.write_line(i_msg => :i_msg,
                i_file_nm => :i_file_nm,
                i_file_dir => :i_file_dir);
end;
4
i_msg
1
﻿This is a line of text written to a named file in a named directory.
5
i_file_nm
1
﻿ut.io.write_line.3.log
5
i_file_dir
1
﻿CORE_LOGS
5
i_mode
0
-5
0
