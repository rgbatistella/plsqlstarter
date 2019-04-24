PL/SQL Developer Test script 3.0
10
declare
  -- Boolean parameters are translated from/to integers: 
  -- 0/1/null <--> false/true/null 
  result boolean;
begin
  -- Call the function
  result := mail.is_smtp_server_avail;
  -- Convert false/true/null to 0/1/null 
  :result := sys.diutil.bool_to_int(result);
end;
1
result
1
1
3
0
