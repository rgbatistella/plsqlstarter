PL/SQL Developer Test script 3.0
18
DECLARE
   l_msg VARCHAR2(32767);
BEGIN
   l_msg := 
   'Line1'||CHR(10)||
   'Line2'||CHR(10)||
   'Line3'||CHR(10)||
   'Line4'||CHR(10)||
   'Line5';
   
   io.write_line(i_msg => l_msg,
             i_file_nm => :i_file_nm,
             i_file_dir => :i_file_dir,
             i_mode => :i_mode);
             
  :result := io.file_length_lines(i_file_nm => :i_file_nm,
                                  i_file_dir => :i_file_dir);
end;
4
result
0
4
i_file_nm
1
﻿ut_file_length_lines.txt
5
i_file_dir
1
﻿CORE_DIR
5
i_mode
1
﻿W
5
0
