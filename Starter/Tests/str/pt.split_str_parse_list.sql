SET SERVEROUTPUT ON
DECLARE
   l_before NUMBER;
   l_after NUMBER;
   l_str VARCHAR2(100) := 'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z';
   l_iterations INTEGER := 10000;
   l_oas typ.tas_large;
   l_stab type_stab;
BEGIN
   
   timer.startme('split_str');
   FOR i IN 1..l_iterations LOOP
      str.split_str(l_str,',',l_oas);
   END LOOP;
   timer.stopme('split_str');
   
   timer.startme('parse_list');
   FOR i IN 1..l_iterations LOOP
      l_stab := str.parse_list(l_str,',');
   END LOOP;
   timer.stopme('parse_list');
   
   dbms_output.put_line('split_str: '||timer.elapsed('split_str'));
   dbms_output.put_line('parse_list: '||timer.elapsed('parse_list'));
END;
/
