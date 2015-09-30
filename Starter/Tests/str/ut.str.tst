PL/SQL Developer Test script 3.0
170
DECLARE
   l_str VARCHAR2(32767);
   l_str_sm VARCHAR2(100);
   l_stab type_stab;
   l_yn  NUMBER;
   
   PROCEDURE print_stab 
   IS
   BEGIN
      IF (l_stab IS NOT NULL AND l_stab.count > 0) THEN
         FOR i IN l_stab.first..l_stab.last LOOP
            dbms_output.put_line('['||i||'] => '||l_stab(i)); 
         END LOOP;
      END IF;
   END;
   
BEGIN

   dbms_output.put_line(CHR(10)||'********** Testing STR.get_diacritic_list *********');
   dbms_output.put_line(str.get_diacritic_list);

   dbms_output.put_line(CHR(10)||'********** Testing STR.get_diacritic_map *********');
   dbms_output.put_line(str.get_diacritic_map);
   
   dbms_output.put_line(CHR(10)||'********** Testing STR.foreign_to_ascii (diacritics included) *********');
   l_str := 'Västerås Trömsø Xepón Jâçanã Japanese char->['||UNISTR('\540D')||']';
   dbms_output.put_line('Orig: '||l_str);
   dbms_output.put_line('New : '||str.foreign_to_ascii(l_str));
   
   dbms_output.put_line(CHR(10)||'********** Testing STR.foreign_to_ascii (multi-byte, Japanese and Russian characters included) *********');
   l_str := 'Hello \540D\524D\5225\540C\50DA\30BB\30C3\30C8\540D\7C3F \0421\043F\0438\0441\043E\043A \043D\0430\043F\0430\0440\043D\0438\043A\043E\0432 \043F\043E \0424\0418\041E World';
   dbms_output.put_line('Orig: '||'ASCII ['||l_str||'] UNICODE ['||UNISTR(l_str)||']');
   dbms_output.put_line('New : '||str.foreign_to_ascii(UNISTR(l_str)));

   dbms_output.put_line(CHR(10)||'********** Testing STR.nonascii_to_ascii (diacritics included) *********');
   l_str := 'Västerås Trömsø Xepón Jâçanã Japanese char->['||UNISTR('\540D')||']';
   dbms_output.put_line('Orig: '||l_str);
   dbms_output.put_line('New : '||str.nonascii_to_ascii(l_str));
   
   l_str := 'We are going to need to save a currency/country code combination in IMOS_MISSIONARY_TRANSACTION to allow for the editing of one-time missionary support payments to change payment method (JPMC, CHECK, LOCAL CHECK). I am putting in a work story for Bill to add columns for this. To start, this will *only* be used to determine the payment methods allowed for the org setup associated with the one time support payment.

In the IMOS_MISTRAN_ACCT_DISTRIBUTION table (which has a many-to-one relationship to IMOS_MISSIONARY_TRANSACTION), we have a CURRENCY column. What I would d like to know is if this column would now be unnecessary. Can a SupportTransaction ever be generated/created that will have distribution lines of different currencies?

If not, then I think I should start using the currency from the IMOS_MISSIONARY_TRANSACTION table and we drop the currency column from IMOS_MISTRAN_ACCT_DISTRIBUTION since it is superfluous. Otherwise, we can leave it as is and nothing should be affected.';
   dbms_output.put_line(CHR(10)||'********** Testing STR.format_to_width at column width of 40 (nowrap) *********');
   dbms_output.put_line(str.format_to_width(l_str,40,'N'));

   dbms_output.put_line(CHR(10)||'********** Testing STR.format_to_width at column width of 80 (nowrap) *********');
   dbms_output.put_line(str.format_to_width(l_str,80,'N'));
   
   dbms_output.put_line(CHR(10)||'********** Testing STR.format_to_width at column width of 120 (nowrap) *********');
   dbms_output.put_line(str.format_to_width(l_str,120,'N'));

   dbms_output.put_line(CHR(10)||'********** Testing STR.format_to_width at column width of 40 (wrap) *********');
   dbms_output.put_line(str.format_to_width(l_str,40,'Y'));

   dbms_output.put_line(CHR(10)||'********** Testing STR.format_to_width at column width of 80 (wrap) *********');
   dbms_output.put_line(str.format_to_width(l_str,80,'Y'));
   
   dbms_output.put_line(CHR(10)||'********** Testing STR.format_to_width at column width of 120 (wrap) *********');
   dbms_output.put_line(str.format_to_width(l_str,120,'Y'));

   l_str := 'This is a short little sentence, with a line
break right between "line" and "break" to demonstrate behavior of format_to_width with really short and long widths.';
   dbms_output.put_line(CHR(10)||'********** Testing STR.format_to_width at column width of 20 (nowrap) *********');
   dbms_output.put_line(str.format_to_width(l_str,20,'N'));

   dbms_output.put_line(CHR(10)||'********** Testing STR.format_to_width at column width of 180 (nowrap) *********');
   dbms_output.put_line(str.format_to_width(l_str,180,'N'));

   dbms_output.put_line(CHR(10)||'********** Testing STR.format_to_width at column width of 20 (wrap) *********');
   dbms_output.put_line(str.format_to_width(l_str,20,'Y'));

   dbms_output.put_line(CHR(10)||'********** Testing STR.format_to_width at column width of 180 (wrap) *********');
   dbms_output.put_line(str.format_to_width(l_str,180,'Y'));

   dbms_output.put_line(CHR(10)||'********** Testing STR.ewc at column width of 20 *********');
   l_str := str.ewc('Column1',20)||str.ewc('Column2',20)||str.ewc('Column3',20)||CHR(10)||
            str.ewc('Hey there',20)||str.ewc('Hello World',20)||str.ewc('Toodles!',20);
   dbms_output.put_line(l_str);
   
   dbms_output.put_line(CHR(10)||'********** Testing STR.parse_list (PATH=.;D:\oracle\10g\db\bin;D:\oracle\ora92\bin;C:\Program Files\Java\jdk1.5.0_11\bin;C:\WINDOWS\system32;C:\WINDOWS;C:\WINDOWS\System32\Wbem;C:\Program Files\Novell\ZENworks;C:\WINDOWS\system32\nls;C:\WINDOWS\system32\nls\ENGLISH;C:\Program Files\Common Files\Roxio Shared\DLLShared;C:\Program Files\InstallShield\AdminStudio\5.5\ConflictSolver;C:\Program Files\QuickTime\QTSystem\;C:\Program Files\Common Files\Roxio Shared\DLLShared\;C:\Program Files\Common Files\Roxio Shared\9.0\DLLShared\;C:\Apps\IDMComp\UltraEdit-32;C:\Apps\Apache\Maven\apache-maven-2.0.8\bin) *********');
   l_stab := str.parse_list('PATH=.;D:\oracle\10g\db\bin;D:\oracle\ora92\bin;C:\Program Files\Java\jdk1.5.0_11\bin;C:\WINDOWS\system32;C:\WINDOWS;C:\WINDOWS\System32\Wbem;C:\Program Files\Novell\ZENworks;C:\WINDOWS\system32\nls;C:\WINDOWS\system32\nls\ENGLISH;C:\Program Files\Common Files\Roxio Shared\DLLShared;C:\Program Files\InstallShield\AdminStudio\5.5\ConflictSolver;C:\Program Files\QuickTime\QTSystem\;C:\Program Files\Common Files\Roxio Shared\DLLShared\;C:\Program Files\Common Files\Roxio Shared\9.0\DLLShared\;C:\Apps\IDMComp\UltraEdit-32;C:\Apps\Apache\Maven\apache-maven-2.0.8\bin',';');
   print_stab;
   
   dbms_output.put_line(CHR(10)||'********** Testing STR.make_list (#) *********');
   l_str := str.make_list(l_stab,'#');
   dbms_output.put_line('make_list: '||l_str);
    
   dbms_output.put_line(CHR(10)||'********** Testing STR.parse_list (,,,0  ,1,2,3,4,5,,6,7,, ) *********');
   dbms_output.put_line('Note: The space after the last comma is seen as a real value, whereas consecutive delimiters (by default) are ignored.');
   l_stab := str.parse_list(',,,0  ,1,2,3,4,5,,6,7,, ');
   print_stab;

   dbms_output.put_line(CHR(10)||'********** Testing STR.make_list (:) *********');
   l_str := str.make_list(l_stab,':');
   dbms_output.put_line('make_list: '||l_str); 
   
   dbms_output.put_line(CHR(10)||'********** Testing STR.trim_str (junk on either end) *********');
   l_str := CHR(9)||CHR(13)||CHR(32)||CHR(239)||'This should be all that is returned.'||CHR(10)||CHR(7)||CHR(128)||CHR(134)||CHR(32);
   dbms_output.put_line('purge_str: |'||str.purge_str(l_str)||'|'); 
   
   l_str := CHR(0)||CHR(7)||'Word'||CHR(9)||'<-TAB '||CHR(10)||'<-NL '||CHR(13)||'<-CR '||
            'Trömsø<-Diacritics '||UNISTR('\540D')||'<-Japanese char '||
            'END'||CHR(128)||CHR(228)||CHR(32)||CHR(0);
   dbms_output.put_line(CHR(10)||'********** Testing STR.purge_str (default, clean all) *********');
   l_str := CHR(9)||CHR(13)||CHR(32)||CHR(239)||l_str||CHR(10)||CHR(7)||CHR(128)||CHR(134)||CHR(32);
   dbms_output.put_line('purge_str: |'||str.purge_str(i_str => l_str,
                                                      i_preserve_tabs => 'N',
                                                      i_preserve_linebreaks => 'N',
                                                      i_convert_diacritics => 'N',
                                                      i_convert_nonascii_to_ascii => 'N')||'|'); 

   dbms_output.put_line(CHR(10)||'********** Testing STR.purge_str (preserve tabs) *********');
   l_str := CHR(9)||CHR(13)||CHR(32)||CHR(239)||l_str||CHR(10)||CHR(7)||CHR(128)||CHR(134)||CHR(32);
   dbms_output.put_line('purge_str: |'||str.purge_str(i_str => l_str,
                                                      i_preserve_tabs => 'Y',
                                                      i_preserve_linebreaks => 'N',
                                                      i_convert_diacritics => 'N',
                                                      i_convert_nonascii_to_ascii => 'N')||'|'); 

   dbms_output.put_line(CHR(10)||'********** Testing STR.purge_str (perserve linebreaks) *********');
   l_str := CHR(9)||CHR(13)||CHR(32)||CHR(239)||l_str||CHR(10)||CHR(7)||CHR(128)||CHR(134)||CHR(32);
   dbms_output.put_line('purge_str: |'||str.purge_str(i_str => l_str,
                                                      i_preserve_tabs => 'N',
                                                      i_preserve_linebreaks => 'Y',
                                                      i_convert_diacritics => 'N',
                                                      i_convert_nonascii_to_ascii => 'N')||'|'); 

   dbms_output.put_line(CHR(10)||'********** Testing STR.purge_str (preserve diacritics as ASCII) *********');
   l_str := CHR(9)||CHR(13)||CHR(32)||CHR(239)||l_str||CHR(10)||CHR(7)||CHR(128)||CHR(134)||CHR(32);
   dbms_output.put_line('purge_str: |'||str.purge_str(i_str => l_str,
                                                      i_preserve_tabs => 'N',
                                                      i_preserve_linebreaks => 'N',
                                                      i_convert_diacritics => 'Y',
                                                      i_convert_nonascii_to_ascii => 'N')||'|'); 

   dbms_output.put_line(CHR(10)||'********** Testing STR.purge_str (preserve non-ASCII as ASCII) *********');
   l_str := CHR(9)||CHR(13)||CHR(32)||CHR(239)||l_str||CHR(10)||CHR(7)||CHR(128)||CHR(134)||CHR(32);
   dbms_output.put_line('purge_str: |'||str.purge_str(i_str => l_str,
                                                      i_preserve_tabs => 'N',
                                                      i_preserve_linebreaks => 'N',
                                                      i_convert_diacritics => 'N',
                                                      i_convert_nonascii_to_ascii => 'Y')||'|'); 

   dbms_output.put_line(CHR(10)||'********** Testing STR.make_list and get_token (ignore_blanks) *********');
   l_stab := str.parse_list(',,,0  ,1,2,3,4,5,,6,7,, ', ',', 'Y');
   l_str := str.make_list(l_stab,',');
   l_str_sm := str.get_token(l_str,',',4,'Y');
   dbms_output.put_line('get_token: Expected [3] Actual ['||l_str_sm||']'); 
   
   dbms_output.put_line(CHR(10)||'********** Testing STR.make_list (don''t ignore blanks) *********');
   l_stab := str.parse_list('0  ,1,,,2,3,,4,5,,6,7,, ', ',', 'N');
   l_str := str.make_list(l_stab,',');
   l_str_sm := str.get_token(l_str,',',5,'N');
   dbms_output.put_line('get_token: Expected [2] Actual ['||l_str_sm||']'); 
   
   dbms_output.put_line(CHR(10)||'********** Testing STR.contains_num (no nums) *********');
   l_str_sm := 'Supercalifragilisticexpialidocious';
   l_yn := str.contains_num(l_str_sm);
   dbms_output.put_line('contains_num: Expected [0] Actual ['||TO_CHAR(l_yn)||']');    

   dbms_output.put_line(CHR(10)||'********** Testing STR.contains_num (has num) *********');
   l_str_sm := 'Superca9lifragilisticexpial0idocious';
   l_yn := str.contains_num(l_str_sm);
   dbms_output.put_line('contains_num: Expected [1] Actual ['||TO_CHAR(l_yn)||']');    



END;
0
0
