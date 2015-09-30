PL/SQL Developer Test script 3.0
8
begin
  logs.set_targets(FALSE,TRUE,FALSE);
  
  logs.to_table(i_log_txt => :i_log_txt,
                i_msg_cd => :i_msg_cd,
                i_sev_cd => :i_sev_cd,
                i_routine_nm => :i_routine_nm);
end;
4
i_log_txt
1
This is the log text for the unit test of logs.to_table
5
i_msg_cd
1
Ad-Hoc Msg
5
i_sev_cd
1
DEBUG
5
i_routine_nm
1
logs.to_table
5
0
