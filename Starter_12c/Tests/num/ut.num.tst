PL/SQL Developer Test script 3.0
90
DECLARE
   l_str VARCHAR2(32767);
   l_str_sm VARCHAR2(100);
   l_ntab1 num_tt;
   l_ntab2 num_tt;
   l_ntab3 num_tt;
   l_yn  NUMBER;
   l_10  INTEGER;
   l_bool BOOLEAN;
   
   PROCEDURE print_ntab (i_ntab IN num_tt)
   IS
   BEGIN
      IF (i_ntab IS NOT NULL AND i_ntab.count > 0) THEN
         FOR i IN i_ntab.first..i_ntab.last LOOP
            dbms_output.put_line('['||i||'] => '||TO_CHAR(i_ntab(i))); 
         END LOOP;
      END IF;
   END;
   
BEGIN
   l_bool := num.IaNb(NULL);
   dbms_output.put_line('IaNb: Expected [FALSE] Actual ['||util.bool_to_str(l_bool)||']'); 
   l_bool := num.IaNb('A');
   dbms_output.put_line('IaNb: Expected [FALSE] Actual ['||util.bool_to_str(l_bool)||']'); 
   l_bool := num.IaNb('999');
   dbms_output.put_line('IaNb: Expected [TRUE] Actual ['||util.bool_to_str(l_bool)||']'); 

   l_10 := num.IaN(NULL);
   dbms_output.put_line('IaN: Expected [0] Actual ['||TO_CHAR(l_10)||']'); 
   l_10 := num.IaN('A');
   dbms_output.put_line('IaN: Expected [0] Actual ['||TO_CHAR(l_10)||']'); 
   l_10 := num.IaN('999');
   dbms_output.put_line('IaN: Expected [1] Actual ['||TO_CHAR(l_10)||']'); 
   
   l_ntab1 := num.parse_list(',,,0  ,1,2,3,99,4,5,,6,7,, ',',','Y');
   dbms_output.put_line('parse_list (leading and trailing junk, consecutive delimiters, ignore blanks/nulls'); 
   print_ntab(l_ntab1);

   l_str := num.make_list(l_ntab1,',');
   dbms_output.put_line('make_list: '||l_str); 

   l_ntab2 := num.parse_list('0:1:2:::3:4:5:6::7',':','N');
   dbms_output.put_line('parse_list (consecutive delimiters, accept blanks/nulls as valid entries'); 
   print_ntab(l_ntab2);

   l_str := num.make_list(l_ntab2,':');
   dbms_output.put_line('make_list: '||l_str); 
   
   l_ntab3 := num.get_set_diff(l_ntab1,l_ntab2);
   dbms_output.put_line('get_set_diff:'); 
   print_ntab(l_ntab3);
   
   l_bool := num.is_oddb(NULL);
   dbms_output.put_line('is_oddb: Expected [NULL] Actual ['||util.bool_to_str(l_bool)||']'); 
   l_bool := num.is_oddb(0);
   dbms_output.put_line('is_oddb: Expected [FALSE] Actual ['||util.bool_to_str(l_bool)||']'); 
   l_bool := num.is_oddb(1);
   dbms_output.put_line('is_oddb: Expected [TRUE] Actual ['||util.bool_to_str(l_bool)||']'); 
   l_bool := num.is_oddb(2);
   dbms_output.put_line('is_oddb: Expected [FALSE] Actual ['||util.bool_to_str(l_bool)||']'); 

   l_bool := num.is_evenb(NULL);
   dbms_output.put_line('is_evenb: Expected [NULL] Actual ['||util.bool_to_str(l_bool)||']'); 
   l_bool := num.is_evenb(0);
   dbms_output.put_line('is_evenb: Expected [TRUE] Actual ['||util.bool_to_str(l_bool)||']'); 
   l_bool := num.is_evenb(1);
   dbms_output.put_line('is_evenb: Expected [FALSE] Actual ['||util.bool_to_str(l_bool)||']'); 
   l_bool := num.is_evenb(2);
   dbms_output.put_line('is_evenb: Expected [TRUE] Actual ['||util.bool_to_str(l_bool)||']'); 

   l_yn := num.is_odd(NULL);
   dbms_output.put_line('is_odd: Expected [NULL] Actual ['||NVL(TO_CHAR(l_yn),'NULL')||']'); 
   l_yn := num.is_odd(0);
   dbms_output.put_line('is_odd: Expected [0] Actual ['||TO_CHAR(l_yn)||']'); 
   l_yn := num.is_odd(1);
   dbms_output.put_line('is_odd: Expected [1] Actual ['||TO_CHAR(l_yn)||']'); 
   l_yn := num.is_odd(2);
   dbms_output.put_line('is_odd: Expected [0] Actual ['||TO_CHAR(l_yn)||']'); 

   l_yn := num.is_even(NULL);
   dbms_output.put_line('is_even: Expected [NULL] Actual ['||NVL(TO_CHAR(l_yn),'NULL')||']'); 
   l_yn := num.is_even(0);
   dbms_output.put_line('is_even: Expected [1] Actual ['||TO_CHAR(l_yn)||']'); 
   l_yn := num.is_even(1);
   dbms_output.put_line('is_even: Expected [0] Actual ['||TO_CHAR(l_yn)||']'); 
   l_yn := num.is_even(2);
   dbms_output.put_line('is_even: Expected [1] Actual ['||TO_CHAR(l_yn)||']'); 
      
END;
0
1
l_string
