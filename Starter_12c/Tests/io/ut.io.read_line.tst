PL/SQL Developer Test script 3.0
18
DECLARE
   l_msg VARCHAR2(32767);
BEGIN
   l_msg :=
   'This is my 1st line.'||CHR(10)||
   'This is my 2nd line.'||CHR(10)||
   'This is my 3rd line.'||CHR(10)||
   'This is my 4th line.';
   
   io.write_line(i_msg      => l_msg,
                 i_file_nm  => :i_file_nm,
                 i_file_dir => :i_file_dir,
                 i_mode     => :i_mode);

   :result := io.read_line(i_file_nm  => :i_file_nm,
                           i_line_num => :i_line_num,
                           i_file_dir => :i_file_dir);
END;
5
result
0
5
i_file_nm
1
﻿ut_read_line.txt
5
i_line_num
1
3
4
i_mode
1
﻿w
5
i_file_dir
1
﻿CORE_DIR
5
0
