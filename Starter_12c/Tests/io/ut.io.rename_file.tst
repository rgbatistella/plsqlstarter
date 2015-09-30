PL/SQL Developer Test script 3.0
22
DECLARE
   -- Boolean parameters are translated from/to integers: 
   -- 0/1/null <--> false/true/null 
   result BOOLEAN;
BEGIN
   io.write_line(i_msg      => :i_msg,
                 i_file_nm  => :i_file_nm,
                 i_file_dir => :i_file_dir,
                 i_mode     => :i_mode);

   io.rename_file(i_old_file_nm  => :i_old_file_nm,
                  i_new_file_nm  => :i_new_file_nm,
                  i_old_file_dir => :i_old_file_dir,
                  i_overwrite    => :i_overwrite);

   result := io.file_exists(i_file_nm => :i_check_file_nm, i_file_dir => :i_file_dir);

   -- Convert false/true/null to 0/1/null 
   :result := SYS.DIUTIL.bool_to_int(result);


END;
10
i_old_file_nm
1
﻿ut_rename_file_before.txt
5
i_new_file_nm
1
﻿ut_rename_file_after.txt
5
i_old_file_dir
1
﻿CORE_DIR
5
i_overwrite
1
﻿Y
5
i_msg
1
﻿This is the message for the rename test.
5
i_file_nm
1
﻿ut_rename_file_before.txt
5
i_file_dir
1
﻿CORE_DIR
5
i_mode
1
﻿w
5
result
0
5
i_check_file_nm
1
﻿ut_rename_file_after.txt
5
0
