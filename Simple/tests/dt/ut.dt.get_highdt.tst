PL/SQL Developer Test script 3.0
7
DECLARE
   l_result DATE;
begin
  -- Call the function
  l_result := dt.get_highdt;
  dbms_output.put_line(TO_CHAR(l_result,'YYYYMonDD'));
end;
1
result
0
-12
0
