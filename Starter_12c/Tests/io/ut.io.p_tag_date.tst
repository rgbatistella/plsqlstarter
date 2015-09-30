PL/SQL Developer Test script 3.0
9
DECLARE
   l_date DATE;
begin
   l_date := TO_DATE('2008Jan01','YYYYMonDD');
   
   io.p(i_str => :i_str,
        i_date => l_date,
        i_fmt => :i_fmt);
end;
2
i_str
1
﻿l_date
5
i_fmt
1
﻿DD-Mon-YYYY
5
0
