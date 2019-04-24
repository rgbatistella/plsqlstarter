PL/SQL Developer Test script 3.0
44
DECLARE
BEGIN
   -- give app_log some data
   FOR i IN 1 .. 12 LOOP
      FOR j IN 1 .. 25 LOOP
         INSERT INTO app_log
            (log_id,
             app_id,
             log_ts,
             sev_cd,
             msg_cd,
             routine_nm,
             line_num,
             log_txt,
             client_id,
             client_ip,
             client_host,
             client_os_user
             )
         VALUES
            (app_log_seq.NEXTVAL,
             (SELECT app_id FROM app WHERE app_cd = 'CORE'),
             TO_TIMESTAMP(TO_CHAR(SYSDATE-365,'YYYY')||TO_CHAR(i,'09')||TO_CHAR(j,'09'),'YYYYMMDD'),
             'INFO',
             'Ad-Hoc Msg',
             'package.proc',
             NULL, -- line_num
             'Bogus Message' || i || ',' || j,
             'bcoulam',
             NULL,
             NULL,
             'WM-COULAMWA'
             );
      END LOOP;
   END LOOP;
   COMMIT;
   
  app_log_api.trim_table(o_rows_deleted => :o_rows_deleted,
                         i_keep_amt => :i_keep_amt,
                         i_keep_amt_uom => :i_keep_amt_uom,
                         i_archive_to_file_flg => :i_archive_to_file_flg
                         --,i_archive_file_nm => :i_archive_file_nm
                         );
END;
5
o_rows_deleted
1
300
4
i_keep_amt
1
5
4
i_keep_amt_uom
1
﻿day
5
i_archive_to_file_flg
1
﻿Y
5
i_archive_file_nm
0
-5
0
