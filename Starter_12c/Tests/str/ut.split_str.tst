PL/SQL Developer Test script 3.0
15
declare
  -- Non-scalar parameters require additional processing 
  oas_results typ.tas_large;
begin
  -- Call the procedure
  str.split_str(i_string => :i_string,
                i_splitchar => :i_splitchar,
                oas_results => oas_results);
                
  IF (oas_results.count > 0) THEN
     FOR i IN oas_results.first..oas_results.last LOOP
        dbms_output.put_line(oas_results(i));
     END LOOP;
  END IF;                
end;
2
i_string
1
﻿A:::B:::C:::D
5
i_splitchar
1
﻿:::
5
0
