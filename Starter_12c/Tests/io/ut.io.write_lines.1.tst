PL/SQL Developer Test script 3.0
12
declare
  -- Non-scalar parameters require additional processing 
  l_msgs t.tas_maxvc2;
begin
  l_msgs(1) := 'First line of text.';
  l_msgs(2) := 'Second line of text.';
  l_msgs(3) := 'Third line of text.';
  
  io.write_lines(i_msgs => l_msgs,
                 i_file_nm => :i_file_nm,
                 i_mode => :i_mode);
end;
3
i_file_nm
1
﻿ut.io.write_lines.1.log
5
i_file_dir
0
-5
i_mode
1
﻿W
5
0
