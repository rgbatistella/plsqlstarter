PL/SQL Developer Test script 3.0
21
DECLARE
   -- Boolean parameters are translated from/to integers: 
   -- 0/1/null <--> false/true/null 
   result BOOLEAN;
BEGIN
   -- Call the procedure
   io.write_line(i_msg      => :i_msg,
                 i_file_nm  => :i_file_nm,
                 i_file_dir => :i_file_dir,
                 i_mode     => :i_mode);

   -- Call the procedure
   io.delete_file(i_file_nm => :i_file_nm, i_file_dir => :i_file_dir);

   -- Call the function
   result := io.file_exists(i_file_nm => :i_file_nm, i_file_dir => :i_file_dir);

   -- Convert false/true/null to 0/1/null 
   :result := SYS.DIUTIL.bool_to_int(result);

END;
5
i_file_nm
1
﻿ut_delete_file.txt
5
i_file_dir
1
﻿CORE_DIR
5
i_msg
1
﻿This is the message for the delete file test.
5
i_mode
1
﻿w
5
result
1
﻿
5
0
