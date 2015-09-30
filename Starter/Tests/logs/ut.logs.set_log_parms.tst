PL/SQL Developer Test script 3.0
14
DECLARE
   l_file_dir VARCHAR2(100);
   l_file_nm VARCHAR2(100);
begin
  -- Call the procedure
  logs.set_log_parms(i_file_dir => :i_file_dir,
                      i_file_nm => :i_file_nm);
  
  l_file_dir := logs.get_log_dir;
  l_file_nm  := logs.get_log_nm; 
  
  dbms_output.put_line(l_file_dir||':'||l_file_nm);                   
                        
end;
2
i_file_dir
1
﻿BOGUS_DIR
5
i_file_nm
1
﻿bogus_file.log
5
0
