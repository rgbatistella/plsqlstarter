PL/SQL Developer Test script 3.0
18
DECLARE
   -- Boolean parameters are translated from/to integers: 
   -- 0/1/null <--> false/true/null 
   ob_exists BOOLEAN;
BEGIN
   io.write_line(i_msg      => :i_msg,
                 i_file_nm  => :i_file_nm,
                 i_file_dir => :i_file_dir,
                 i_mode     => :i_mode);

   io.get_file_props(i_file_nm  => :i_file_nm,
                     i_file_dir => :i_file_dir,
                     ob_exists  => ob_exists,
                     on_length  => :on_length);

   -- Convert false/true/null to 0/1/null 
   :ob_exists := SYS.DIUTIL.bool_to_int(ob_exists);
END;
6
i_file_nm
1
﻿ut_get_file_props.txt
5
i_file_dir
1
﻿CORE_DIR
5
ob_exists
0
3
on_length
0
4
i_msg
1
﻿This is the message for the get_file_props test.
5
i_mode
1
﻿w
5
0
