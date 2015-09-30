PL/SQL Developer Test script 3.0
32
begin
  -- Call the procedure
  env.init_client_ctx(i_client_id => 'bcoulam');
  
  app_log_api.ins(i_log_txt => :i_log_txt);
  
  app_log_api.ins(i_log_txt => :i_log_txt,
                  i_sev_cd => :i_sev_cd);
                  
  app_log_api.ins(i_log_txt => :i_log_txt,
                  i_sev_cd => :i_sev_cd,
                  i_msg_cd => :i_msg_cd);

  app_log_api.ins(i_log_txt => :i_log_txt,
                  i_sev_cd => :i_sev_cd,
                  i_msg_cd => :i_msg_cd,
                  i_routine_nm => :i_routine_nm);

  app_log_api.ins(i_log_txt => :i_log_txt,
                  i_sev_cd => :i_sev_cd,
                  i_msg_cd => :i_msg_cd,
                  i_routine_nm => :i_routine_nm,
                  i_line_num => :i_line_num);
                  

  app_log_api.ins(i_log_txt => :i_log_txt,
                  i_sev_cd => :i_sev_cd,
                  i_msg_cd => :i_msg_cd,
                  i_routine_nm => $$PLSQL_UNIT,
                  i_line_num => $$PLSQL_LINE);
                                                                        
end;
5
i_log_txt
1
﻿This is a test log message.
5
i_sev_cd
1
﻿INFO
5
i_msg_cd
1
﻿Ad-Hoc Msg
5
i_routine_nm
1
﻿bogus_proc
5
i_line_num
1
500
3
0
