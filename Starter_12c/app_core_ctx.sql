CREATE OR REPLACE CONTEXT app_core_ctx USING &&fmwk_home+.env
/

-- Script to show the context attributes set so far.
--SET SERVEROUTPUT ON
--DECLARE
--   l_list dbms_session.AppCtxTabTyp;
--   l_size NUMBER;
--BEGIN
--   dbms_session.list_context(list => l_list, lsize => l_size);
--   dbms_output.put_line('Number of contexts returned: '||l_list.COUNT);
--   dbms_output.put_line('Size returned: '||l_size);
--   IF (l_size > 0) THEN
--      FOR i IN l_list.first..l_list.last LOOP
--         dbms_output.put_line(l_list(i).namespace||'.'||l_list(i).attribute||'='||l_list(i).value); 
--      END LOOP;
--   END IF;
--END;
--/

