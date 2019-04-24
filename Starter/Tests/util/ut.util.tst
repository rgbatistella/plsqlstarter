PL/SQL Developer Test script 3.0
165
DECLARE
   l_bool_str VARCHAR2(30);
   l_bool     BOOLEAN;
   
   l_date DATE;
   l_num NUMBER;
   l_str VARCHAR2(4000);
   
   l_result NUMBER;
   
   PROCEDURE determine_truth (i_expected IN VARCHAR2, i_bool IN BOOLEAN)
   IS
   BEGIN
      IF (i_bool) THEN
         dbms_output.put_line('Expected ['||i_expected||'] Actual [TRUE]');
      ELSE
         dbms_output.put_line('Expected ['||i_expected||'] Actual [FALSE]');
      END IF;
   END determine_truth;
BEGIN
   -- Unit Tests for UTIL package (a subset of DDL_UTILS)
   
   dbms_output.put_line('********  util.bool_to_str  *********');
   l_bool_str := util.bool_to_str(TRUE);
   dbms_output.put_line('Expected [TRUE] Actual ['||l_bool_str||']');
   l_bool_str := util.bool_to_str(FALSE);
   dbms_output.put_line('Expected [FALSE] Actual ['||l_bool_str||']');
   l_bool_str := util.bool_to_str(NULL);
   dbms_output.put_line('Expected [NULL] Actual ['||l_bool_str||']');
   
   dbms_output.put_line('********  util.bool_to_num  *********');
   l_num := util.bool_to_num(TRUE);
   dbms_output.put_line('Expected [1] Actual ['||l_num||']');
   l_num := util.bool_to_num(FALSE);
   dbms_output.put_line('Expected [0] Actual ['||l_num||']');
   l_num := util.bool_to_num(NULL);
   dbms_output.put_line('Expected [] Actual ['||l_num||']');

   dbms_output.put_line('********  util.str_to_bool  *********');
   l_bool := util.str_to_bool('TRUE'); determine_truth('TRUE', l_bool);
   l_bool := util.str_to_bool('true'); determine_truth('TRUE', l_bool);
   l_bool := util.str_to_bool('T'); determine_truth('TRUE', l_bool);
   l_bool := util.str_to_bool('t'); determine_truth('TRUE', l_bool);
   l_bool := util.str_to_bool('YES'); determine_truth('TRUE', l_bool);
   l_bool := util.str_to_bool('yes'); determine_truth('TRUE', l_bool);
   l_bool := util.str_to_bool('Y'); determine_truth('TRUE', l_bool);
   l_bool := util.str_to_bool('y'); determine_truth('TRUE', l_bool);
   l_bool := util.str_to_bool('1'); determine_truth('TRUE', l_bool);

   l_bool := util.str_to_bool('FALSE'); determine_truth('FALSE', l_bool);
   l_bool := util.str_to_bool('false'); determine_truth('FALSE', l_bool);
   l_bool := util.str_to_bool('F'); determine_truth('FALSE', l_bool);
   l_bool := util.str_to_bool('f'); determine_truth('FALSE', l_bool);
   l_bool := util.str_to_bool('NO'); determine_truth('FALSE', l_bool);
   l_bool := util.str_to_bool('no'); determine_truth('FALSE', l_bool);
   l_bool := util.str_to_bool('N'); determine_truth('FALSE', l_bool);
   l_bool := util.str_to_bool('n'); determine_truth('FALSE', l_bool);
   l_bool := util.str_to_bool('0'); determine_truth('FALSE', l_bool);
   l_bool := util.str_to_bool(''); determine_truth('FALSE', l_bool);
   l_bool := util.str_to_bool(NULL); determine_truth('FALSE', l_bool);

   dbms_output.put_line('********  util.num_to_bool  *********');
   l_bool := util.num_to_bool(1); determine_truth('TRUE', l_bool);
   l_bool := util.num_to_bool(-1); determine_truth('TRUE', l_bool);
   l_bool := util.num_to_bool(99); determine_truth('TRUE', l_bool);

   l_bool := util.num_to_bool(0); determine_truth('FALSE', l_bool);
   l_bool := util.num_to_bool(NULL); determine_truth('FALSE', l_bool);
 

   dbms_output.put_line('********  util.ifnn  *********');
   l_date := NULL;
   l_num := NULL;
   l_str := NULL;
   dbms_output.put_line('Expected [9999Dec31] Actual ['||TO_CHAR(util.ifnn(l_date,TO_DATE('2008Dec31','YYYYMonDD'),TO_DATE('9999Dec31','YYYYMonDD')),'YYYYMonDD')||']'); 
   dbms_output.put_line('Expected [999] Actual ['||TO_CHAR(util.ifnn(l_num,100,999))||']'); 
   dbms_output.put_line('Expected [World] Actual ['||util.ifnn(l_str,'Hello','World')||']'); 

   dbms_output.put_line('Expected [NULL] Actual ['||NVL(TO_CHAR(util.ifnn(l_date,TO_DATE('2008Jan01','YYYYMonDD')),'YYYYMonDD'),'NULL')||']'); 
   dbms_output.put_line('Expected [NULL] Actual ['||NVL(TO_CHAR(util.ifnn(l_num,100)),'NULL')||']'); 
   dbms_output.put_line('Expected [NULL] Actual ['||NVL(util.ifnn(l_str,'Hello'),'NULL')||']'); 

   l_date := TO_DATE('2008Mar01','YYYYMonDD');
   l_num := 99;
   l_str := 'Hi';
   dbms_output.put_line('Expected [2008Dec31] Actual ['||TO_CHAR(util.ifnn(l_date,TO_DATE('2008Dec31','YYYYMonDD'),TO_DATE('9999Dec31','YYYYMonDD')),'YYYYMonDD')||']'); 
   dbms_output.put_line('Expected [100] Actual ['||TO_CHAR(util.ifnn(l_num,100,999))||']'); 
   dbms_output.put_line('Expected [Hello] Actual ['||util.ifnn(l_str,'Hello','World')||']'); 

   dbms_output.put_line('********  util.ifnull  *********');
   l_date := TO_DATE('2008Mar01','YYYYMonDD');
   l_num := 99;
   l_str := 'Hi';
   dbms_output.put_line('Expected [9999Dec31] Actual ['||TO_CHAR(util.ifnull(l_date,TO_DATE('2008Dec31','YYYYMonDD'),TO_DATE('9999Dec31','YYYYMonDD')),'YYYYMonDD')||']'); 
   dbms_output.put_line('Expected [999] Actual ['||TO_CHAR(util.ifnull(l_num,100,999))||']'); 
   dbms_output.put_line('Expected [World] Actual ['||util.ifnull(l_str,'Hello','World')||']'); 

   dbms_output.put_line('Expected [NULL] Actual ['||NVL(TO_CHAR(util.ifnull(l_date,TO_DATE('2008Dec31','YYYYMonDD')),'YYYYMonDD'),'NULL')||']'); 
   dbms_output.put_line('Expected [NULL] Actual ['||NVL(TO_CHAR(util.ifnull(l_num,100)),'NULL')||']'); 
   dbms_output.put_line('Expected [NULL] Actual ['||NVL(util.ifnull(l_str,'Hello'),'NULL')||']'); 

   l_date := NULL;
   l_num := NULL;
   l_str := NULL;
   dbms_output.put_line('Expected [2008Dec31] Actual ['||NVL(TO_CHAR(util.ifnull(l_date,TO_DATE('2008Dec31','YYYYMonDD'),TO_DATE('9999Dec31','YYYYMonDD')),'YYYYMonDD'),'NULL')||']'); 
   dbms_output.put_line('Expected [100] Actual ['||NVL(TO_CHAR(util.ifnull(l_num,100,999)),'NULL')||']'); 
   dbms_output.put_line('Expected [Hello] Actual ['||NVL(util.ifnull(l_str,'Hello','World'),'NULL')||']'); 

   dbms_output.put_line('********  util.ite  *********');
   dbms_output.put_line('Note: Function ite() already fully exercized by calling ifnn and ifnull.'); 
   
   dbms_output.put_line('********  util.obj_exists  *********');
   dbms_output.put_line('Expected [TRUE] Actual ['||util.bool_to_str(util.obj_exists('APP_DB'))||']'); 
   dbms_output.put_line('Expected [TRUE] Actual ['||util.bool_to_str(util.obj_exists('APP_DB',util.gc_table))||']'); 
   dbms_output.put_line('Expected [TRUE] Actual ['||util.bool_to_str(util.obj_exists('APP_DB_PK'))||']'); 
   dbms_output.put_line('Expected [TRUE] Actual ['||util.bool_to_str(util.obj_exists('APP_DB_PK',util.gc_index))||']');
   dbms_output.put_line('Expected [TRUE] Actual ['||util.bool_to_str(util.obj_exists('APP_LOG_SEQ'))||']'); 
   dbms_output.put_line('Expected [TRUE] Actual ['||util.bool_to_str(util.obj_exists('APP_LOG_SEQ',util.gc_sequence))||']');
   dbms_output.put_line('Expected [TRUE] Actual ['||util.bool_to_str(util.obj_exists('AEV_APP_ID_FK',util.gc_constraint))||']');
   dbms_output.put_line('Expected [FALSE] Actual ['||util.bool_to_str(util.obj_exists('AEV_APP_ID_FK'))||']');
   dbms_output.put_line('Expected [TRUE] Actual ['||util.bool_to_str(util.obj_exists('APP_LOG_API',util.gc_package))||']');
   dbms_output.put_line('Expected [TRUE] Actual ['||util.bool_to_str(util.obj_exists('APP_BIUD',util.gc_trigger))||']');
   dbms_output.put_line('Expected [TRUE] Actual ['||util.bool_to_str(util.obj_exists('APP_PARM_VW',util.gc_view))||']');
   dbms_output.put_line('Expected [TRUE] Actual ['||util.bool_to_str(util.obj_exists('TYPE_NTAB',util.gc_type))||']');

   dbms_output.put_line('********  util.attr_exists  *********');
   dbms_output.put_line('Expected [TRUE] Actual ['||util.bool_to_str(util.attr_exists('APP_DB','DB_ID',util.gc_column))||']'); 
   dbms_output.put_line('Expected [TRUE] Actual ['||util.bool_to_str(util.attr_exists('ENV','get_app_cd',util.gc_routine))||']'); 

   dbms_output.put_line('********  util.get_max_pk_val  *********');
   l_result := util.get_max_pk_val('app_msg');
   dbms_output.put_line('Expected [101] Actual ['||l_result||']'); 
   
   dbms_output.put_line('********  util.get_mime_type and get_otx_doc_type *********');
   l_str := util.get_mime_type('My Word Doc.docx');
   dbms_output.put_line('Expected [application/vnd.openxmlformats-officedocument.wordprocessingml.document] Actual ['||l_str||']');
   l_str := util.get_otx_doc_type(l_str);
   dbms_output.put_line('Expected [BINARY] Actual ['||l_str||']'); 
    
   l_str := util.get_mime_type('My Old Spreadsheet.xls');
   dbms_output.put_line('Expected [application/vnd.ms-excel] Actual ['||l_str||']'); 
   l_str := util.get_otx_doc_type(l_str);
   dbms_output.put_line('Expected [BINARY] Actual ['||l_str||']'); 

   l_str := util.get_mime_type('My PDF.pdf');
   dbms_output.put_line('Expected [application/pdf] Actual ['||l_str||']'); 
   l_str := util.get_otx_doc_type(l_str);
   dbms_output.put_line('Expected [BINARY] Actual ['||l_str||']'); 

   l_str := util.get_mime_type('MyNotes.rtf');
   dbms_output.put_line('Expected [text/rtf] Actual ['||l_str||']'); 
   l_str := util.get_otx_doc_type(l_str);
   dbms_output.put_line('Expected [TEXT] Actual ['||l_str||']'); 

   l_str := util.get_mime_type('MyPic.gif');
   dbms_output.put_line('Expected [image/gif] Actual ['||l_str||']'); 
   l_str := util.get_otx_doc_type(l_str);
   dbms_output.put_line('Expected [IGNORE] Actual ['||l_str||']'); 

   l_str := util.get_mime_type('My Unrecognized.bogus');
   dbms_output.put_line('Expected [application/octet-stream] Actual ['||l_str||']'); 
   l_str := util.get_otx_doc_type(l_str);
   dbms_output.put_line('Expected [BINARY] Actual ['||l_str||']'); 
   
END;
0
0
