PL/SQL Developer Test script 3.0
4
BEGIN
   io.set_default_filename(i_default_filename => :i_default_filename);
   :result := io.get_default_filename;
END;
2
result
0
5
i_default_filename
1
﻿bogus_default_filename.log
5
0
