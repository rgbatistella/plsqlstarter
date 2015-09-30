PL/SQL Developer Test script 3.0
23
DECLARE
   -- Boolean parameters are translated from/to integers: 
   -- 0/1/null <--> false/true/null 
   result BOOLEAN;
BEGIN
   io.write_line(i_msg => :i_msg,
                i_file_nm => :i_file_nm,
                i_file_dir => :i_file_dir,
                i_mode => :i_mode);
                
  io.move_file(i_src_dir => :i_src_dir,
               i_src_file => :i_src_file,
               i_dest_dir => :i_dest_dir,
               i_dest_file => :i_dest_file,
               i_overwrite => :i_overwrite);

   result := io.file_exists(i_file_nm => :i_check_file_nm, i_file_dir => :i_check_file_dir);

   -- Convert false/true/null to 0/1/null 
   :result := SYS.DIUTIL.bool_to_int(result);


END;
12
i_src_dir
1
﻿CORE_DIR
5
i_src_file
1
﻿ut_source_file.txt
5
i_dest_dir
1
﻿CORE_LOGS
5
i_dest_file
1
﻿ut_moved_file.txt
5
i_overwrite
1
﻿Y
5
i_msg
1
﻿This is the message for the move_file test.
5
i_file_nm
1
﻿ut_source_file.txt
5
i_file_dir
1
﻿CORE_DIR
5
i_mode
1
﻿w
5
i_check_file_nm
1
﻿ut_moved_file.txt
5
i_check_file_dir
1
﻿CORE_LOGS
5
result
1
﻿
5
0
