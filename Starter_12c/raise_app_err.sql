CREATE OR REPLACE PROCEDURE raise_app_err
(
   i_ude_msg IN VARCHAR2,
   i_ude_id IN INTEGER DEFAULT -20000
)
IS
/**-----------------------------------------------------------------------------
 Used to wrap RAISE_APPLICATION_ERROR and re-raising exceptions with a package
 named EXCP. Found that re-raising Oracle errors from 4 layers down (logs.err ->
 logs.msg -> excp.throw -> internal anonymous block to re-raise) left a rather
 messy error stack.
 
 Decided to simplify. Now, if an error is trapped and it's an Oracle error, just
 log the error (logs.err) and then call RAISE. If it's a user-defined exception,
 call this raise_app_err standalone procedure.
 
 Calling raise_app_err consistently replaces direct calls to 
 RAISE_APPLICATION_ERROR making error handling more consistent.
 
%usage
 raise_app_err, by itself, does no logging. log the error first, then raise it.
    l_msg := 'Incoming Queue Error: Payload is empty.';
    logs.err(l_msg);
    raise_app_err(l_msg,-20050);
    
    OR
    raise_app_err('Payload is empty.'); -- if error ID is not important, defaults to -20000

 which logs the message and then calls raises the user-defined exception.

%param i_ude_id Positive number, a message ID from custom table of common messages.
                Or negative number, from the -20000 to -20999 user-defined range.
                Will also handle negative, pre-defined Oracle error numbers, but those
                should be raised by RAISE.

%param i_ude_msg  Custom message to be raised along with the user-defined exception ID.
------------------------------------------------------------------------------*/
   l_msg typ.t_maxvc2;
BEGIN
   -- If raise() is called without a message when a real exception has not 
   -- occurred, the default SQLERRM will be "ORA-0000: normal, successful completion"
   -- which is useless, so we'll try to look up a canned message using the
   -- msg_id.
   IF (i_ude_msg IS NULL OR i_ude_msg LIKE 'ORA-0000:%') THEN
         l_msg := 'Unknown error.';
   ELSE
      l_msg := i_ude_msg;
   END IF;
   
   -- if user-defined in Oracle-provided range
   IF (i_ude_id BETWEEN -20999 AND -20000) THEN
   
      RAISE_APPLICATION_ERROR(i_ude_id, SUBSTR(l_msg,1,2048), FALSE); -- 3rd parm puts the UDE on the stack

   -- if user-defined positive error from APP_MSG table
   ELSIF ((i_ude_id >= 0 AND i_ude_id <> 100)) THEN
      -- UDE = User Defined Error ID
      RAISE_APPLICATION_ERROR(-20000, SUBSTR('UDE['||i_ude_id||'] '||l_msg,1,2048), FALSE);
   
   -- if no data found (can't be bound to local)
   ELSIF (i_ude_id IN (100,-1403) )THEN
   
      RAISE NO_DATA_FOUND;
   
   -- If not positive, user-defined or one of the special no_data_found
   -- exceptions, it must be an Oracle built-in error. So re-raise as-is.
   ELSE
      EXECUTE IMMEDIATE
      'DECLARE'||
      '   lx EXCEPTION;'||
      '   PRAGMA EXCEPTION_INIT(lx,'||TO_CHAR(i_ude_id)||');'||
      'BEGIN'||
      '   RAISE lx;'||
      'END;'
      ;
   END IF;
END raise_app_err;
/
