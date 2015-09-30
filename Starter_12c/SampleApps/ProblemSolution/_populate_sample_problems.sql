--------------------------------------------------------------------------------
INSERT INTO ps_prob
   (prob_id
   ,prob_key
   ,prob_key_txt
   ,prob_notes
   ,prob_src_id
   ,otx_sync_col)
VALUES
   (ps_prob_seq.NEXTVAL
   ,'ORA-03113'
   ,'End-of-file on communication channel (Network connection lost)'
   ,'Common error encountered when connection to the database is severed.'
   ,1
   ,'Y');

INSERT INTO ps_sol
   (sol_id
   ,prob_id
   ,sol_notes)
VALUES
   (ps_sol_seq.NEXTVAL
   ,(SELECT prob_id FROM ps_prob WHERE prob_key = 'ORA-03113')
   ,'This error sometimes happens when you encounter nasty bugs in Oracle. 
   But the most typical explanation for a 3113 is that something about the network between you and the database went sour. 
   Check your cable or wireless. 
   Ensure the database host and database are still reachable with ping and tnsping.
   Usually a 3113 just goes away when you try to connect again.');

--------------------------------------------------------------------------------
INSERT INTO ps_prob
   (prob_id
   ,prob_key
   ,prob_key_txt
   ,prob_notes
   ,prob_src_id
   ,otx_sync_col)
VALUES
   (ps_prob_seq.NEXTVAL
   ,'TNS-12523'
   ,'TNS:listener could not find instance appropriate for the client connection.'
   ,'Encountered this error in the listener.log of both 10g XE and 10g EE when attempting to contact the EPG over http, port 8080.'
   ,1
   ,'Y');

INSERT INTO ps_sol
   (sol_id
   ,prob_id
   ,sol_notes)
VALUES
   (ps_sol_seq.NEXTVAL
   ,(SELECT prob_id FROM ps_prob WHERE prob_key = 'TNS-12523')
   ,'One solution to this problem turned out to be a local client firewall (Sophos). It had a default configuration from 
   corporate HQ engineering that prevented http requests. Both turning off the firewall and later getting engineering to
   put me in the special Oracle group where that sort of traffic was allowed solved my problem.');

--------------------------------------------------------------------------------
INSERT INTO ps_prob
   (prob_id
   ,prob_key
   ,prob_key_txt
   ,prob_notes
   ,prob_src_id
   ,otx_sync_col)
VALUES
   (ps_prob_seq.NEXTVAL
   ,'DAD Not Reachable'
   ,'Attempts to reach procs in the schema behind the DAD returned nothing. No 404 error page. No HTML whatsoever. Just a blank page.'
   ,'Mainly tried changing the port being used by the EPG to listen for HTTP traffic. No luck. 
   Tried the same with Oracle XE which comes with a built-in setup for HTTP traffic to support APEX. Still didn''t work.'
   ,2
   ,'Y');

INSERT INTO ps_sol
   (sol_id
   ,prob_id
   ,sol_notes)
VALUES
   (ps_sol_seq.NEXTVAL
   ,(SELECT prob_id FROM ps_prob WHERE prob_key = 'DAD Not Reachable')
   ,'No error message or returned HTML should have been a big clue that the HTTP request was not reaching the EPG.
   Checking the Windows application log didn''t help. Finally checked the laptop''s firewall client logs 
   and found tnslsnr.exe and oracle.exe were being rejected by the firewall. Got the engineering group to
   add me to a special Oracle group that allows that kind of TCP traffic on my laptop. EPG is working fine now.');   

--------------------------------------------------------------------------------
INSERT INTO ps_prob
   (prob_id
   ,prob_key
   ,prob_key_txt
   ,prob_notes
   ,prob_src_id
   ,otx_sync_col)
VALUES
   (ps_prob_seq.NEXTVAL
   ,'printjoins'
   ,''
   ,'Using the printjoins attribute of the Oracle Text lexer preference does not seem to be working. Indexing
   with printjoins in the lexer does not complain and the tokens in the underlying DR$ index table seem fine.
   But attempts to search with the CONTAINS operator don''t yield expected results. This is true for both
   dashes and underscore characters.'
   ,3
   ,'Y');

INSERT INTO ps_sol
   (sol_id
   ,prob_id
   ,sol_notes)
VALUES
   (ps_sol_seq.NEXTVAL
   ,(SELECT prob_id FROM ps_prob WHERE prob_key = 'printjoins')
   ,'You must escape the "-" or "_" characters if the user inputs them in the search string in order for the CONTAINS operator to see them and include them in the search against the Context index.');   

--------------------------------------------------------------------------------
INSERT INTO ps_prob
   (prob_id
   ,prob_key
   ,prob_key_txt
   ,prob_notes
   ,prob_src_id
   ,otx_sync_col)
VALUES
   (ps_prob_seq.NEXTVAL
   ,'Explorer Stinks'
   ,'Much functionality was lost with Windows NT 3.51 File Explorer. Really miss double panes.'
   ,''
   ,4
   ,'Y');

INSERT INTO ps_sol
   (sol_id
   ,prob_id
   ,sol_notes)
VALUES
   (ps_sol_seq.NEXTVAL
   ,(SELECT prob_id FROM ps_prob WHERE prob_key = 'Explorer Stinks')
   ,'Download and enjoy FreeCommander. http://www.freecommander.com. Has everything a developer needs.');   
INSERT INTO ps_sol
   (sol_id
   ,prob_id
   ,sol_notes)
VALUES
   (ps_sol_seq.NEXTVAL
   ,(SELECT prob_id FROM ps_prob WHERE prob_key = 'Explorer Stinks')
   ,'You could also try eXplorer2 from zabkat.');   

COMMIT;
 

