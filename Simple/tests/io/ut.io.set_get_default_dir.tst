PL/SQL Developer Test script 3.0
4
BEGIN
   io.set_default_dir(i_default_dir => :i_default_dir);
   :result := io.get_default_dir;
END;
2
i_default_dir
1
﻿BOGUS_DIR
5
result
0
5
0
