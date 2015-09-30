PL/SQL Developer Test script 3.0
15
/* NOTE: I cannot get this one to work, I expected 10 or 11 bytes, depending on
whether UTL_FILE appended each line with a line termination character. It seems
that it ends each line with a LF and each file with a CR, so there is always an
extra blank line at the end (and thus the 12th character) whether you want it 
or not
*/
BEGIN
   io.write_line(i_msg      => :i_msg,
                 i_file_nm  => :i_file_nm,
                 i_file_dir => :i_file_dir,
                 i_mode     => :i_mode);

   :result := io.file_length_bytes(i_file_nm  => :i_file_nm,
                                   i_file_dir => :i_file_dir);
END;
5
result
0
4
i_file_nm
1
﻿ut_file_length_bytes.txt
5
i_file_dir
1
﻿CORE_DIR
5
i_msg
1
﻿1234567890
5
i_mode
1
﻿w
5
0
