PL/SQL Developer Test script 3.0
8
DECLARE
   l_date DATE;
BEGIN
   l_date := TO_DATE('2008Mar20 18:30:05','YYYYMonDD HH24:MI:SS');
   
  io.p(i_date => l_date,
       i_fmt => :i_fmt);
end;
1
i_fmt
1
﻿Mon-DD (YYYY) HH24:MI:SS
5
0
