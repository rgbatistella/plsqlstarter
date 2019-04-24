PL/SQL Developer Test script 3.0
13
begin
  logs.set_targets(FALSE,FALSE,TRUE);
  
  logs.to_file(i_msg => :i_msg,
               i_msg_cd => :i_msg_cd,
               i_sev_cd => :i_sev_cd,
               i_routine_nm => :i_routine_nm,
               i_file_nm => :i_file_nm,
               i_file_dir => :i_file_dir);

  -- now check the directory for the file
                 
end;
6
i_msg
1
﻿This is the test message for logs.to_file
5
i_msg_cd
1
﻿Ad-Hoc Msg
5
i_sev_cd
1
﻿INFO
5
i_routine_nm
1
﻿logs.to_file
5
i_file_nm
1
﻿ut.logs.to_file.txt
5
i_file_dir
1
﻿CORE_DIR
5
0
