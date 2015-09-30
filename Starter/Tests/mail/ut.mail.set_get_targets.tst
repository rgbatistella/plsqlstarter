PL/SQL Developer Test script 3.0
11
DECLARE
   l_targets VARCHAR2(80);
begin
  -- Call the procedure
  mail.set_targets(i_smtp => TRUE,
                   i_table => TRUE,
                   i_file => TRUE);
                   
  l_targets := mail.get_targets;   
  dbms_output.put_line(l_targets);                 
end;
0
0
