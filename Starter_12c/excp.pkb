CREATE OR REPLACE PACKAGE BODY excp
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      1997Dec30 Creation

<i>
    __________________________  LGPL License  ____________________________
    Copyright (C) 1997-2008 Bill Coulam

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

*******************************************************************************/
AS

--------------------------------------------------------------------------------
--                 PACKAGE CONSTANTS, VARIABLES, TYPES, EXCEPTIONS
--------------------------------------------------------------------------------
--gc_pkg_nm CONSTANT user_source.name%TYPE := 'excp';

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
PROCEDURE assert
(
   i_expr       IN BOOLEAN,
   i_msg        IN VARCHAR2,
   i_raise_excp IN BOOLEAN DEFAULT TRUE,
   i_excp_nm    IN VARCHAR2 DEFAULT NULL,
   i_routine_nm IN app_log.routine_nm%TYPE DEFAULT NULL,
   i_line_num   IN app_log.line_num%TYPE DEFAULT NULL
) IS
   l_routine_nm  app_log.routine_nm%TYPE := i_routine_nm;
   l_line_num    app_log.line_num%TYPE := i_line_num;
BEGIN
   -- We don't worry about location and line number if the caller wanted an
   -- exception to be raised. This is because the exception itself will come
   -- with its own stack that will indicate which routine contained the assertion.
   IF (i_raise_excp = FALSE) THEN
      IF (i_routine_nm IS NULL) THEN
         l_routine_nm := utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(2));
      END IF;

      IF (i_line_num IS NULL) THEN
         l_line_num := utl_call_stack.unit_line(2);
      END IF;
   END IF;

   -- If expression asserted is false, then log and/or re-raise the error
   IF (NVL(i_expr, FALSE) = FALSE) THEN
      IF (i_raise_excp) THEN
         IF (i_excp_nm IS NOT NULL) THEN
            EXECUTE IMMEDIATE 'BEGIN'||
                              '   RAISE ' || i_excp_nm || ';'||
                              'END;';
         ELSE
            RAISE_APPLICATION_ERROR(-20000, i_msg);
         END IF;
      ELSE
         -- we replicate some functionality of the MSGS package here because
         -- the EXCP package was meant to be very low level, dependent on nothing.
         dbms_output.put_line(cnst.error || cnst.sepchar || '(Assertion Failure) ' ||
                              '['||l_routine_nm||' line '||NVL(TO_CHAR(l_line_num),'?')||'] '|| i_msg);
         app_log_api.ins(i_msg, cnst.error, 'Assertion Failure', l_routine_nm, l_line_num);
      END IF; -- if exception is provided

   END IF; -- if expression is false

END assert;

--------------------------------------------------------------------------------
PROCEDURE throw
(
   i_msg_id IN app_msg.msg_id%TYPE DEFAULT SQLCODE,
   i_msg IN VARCHAR2 DEFAULT SQLERRM
)
IS
   l_msg typ.t_maxvc2;
BEGIN
   -- If throw() is called without a message when a real exception has not
   -- occurred, the default SQLERRM will be "ORA-0000: normal, successful completion"
   -- which is useless, so we'll try to look up a canned message using the
   -- msg_id.
   IF (i_msg IS NULL OR i_msg LIKE 'ORA-0000:%') THEN
      l_msg := msgs.get_msg(i_msg_id);
   ELSE
      l_msg := i_msg;
   END IF;

   -- adds the program step caught from logs.dbg() calls
   IF logs.g_step IS NOT NULL THEN
     l_msg := l_msg || ' step['||logs.g_step||']';
   END IF;

   -- if user-defined in Oracle-provided range
   IF (i_msg_id BETWEEN -20999 AND -20000) THEN

      RAISE_APPLICATION_ERROR(i_msg_id, SUBSTR(l_msg,1,2048));

   -- if user-defined positive error from APP_MSG table
   -- OR
   -- if error ID from the "strange range"
   ELSIF ((i_msg_id >= 0 AND i_msg_id <> 100) OR (i_msg_id BETWEEN -21299 AND -21000)) THEN
      -- UDE = User Defined Error ID
      RAISE_APPLICATION_ERROR(-20000, SUBSTR('UDE['||i_msg_id||'] '||l_msg,1,2048));

   -- if no data found (can't be bound to local)
   ELSIF (i_msg_id IN (100,-1403) )THEN

      -- IF there is a "program step" raise an error with it first, so it's in the error stack
      IF logs.g_step IS NOT null THEN
        BEGIN
          raise_application_error (-20000,SUBSTR(l_msg,1,2048));
        EXCEPTION
          WHEN others THEN
            -- then raise the no_data_found
            RAISE no_data_found;
        END;
      ELSE
        RAISE no_data_found;
      END IF;

   -- if not positive, user-defined or one of the special no_data_found
   -- exceptions, it must be an Oracle built-in error, re-raise as is.
   ELSE
      -- IF there is a "program step" raise an error with it first, so it's in the error stack
      IF logs.g_step IS NOT null THEN
        BEGIN
          raise_application_error (-20000,SUBSTR(l_msg,1,2048));
        EXCEPTION
          WHEN others THEN
            -- then raise the exception
            EXECUTE IMMEDIATE
            'DECLARE'||
            '   lx EXCEPTION;'||
            '   PRAGMA EXCEPTION_INIT(lx,'||TO_CHAR(i_msg_id)||');'||
            'BEGIN'||
            '   RAISE lx;'||
            'END;'
            ;
            END;
      ELSE
        EXECUTE IMMEDIATE
        'DECLARE'||
        '   lx EXCEPTION;'||
        '   PRAGMA EXCEPTION_INIT(lx,'||TO_CHAR(i_msg_id)||');'||
        'BEGIN'||
        '   RAISE lx;'||
        'END;'
        ;
      END IF;

   END IF;
END throw;

--------------------------------------------------------------------------------
PROCEDURE throw
(
   i_msg_cd IN app_msg.msg_cd%TYPE,
   i_msg IN VARCHAR2 DEFAULT NULL
)
IS
BEGIN
   throw(msgs.get_msg_id(i_msg_cd), NVL(i_msg, msgs.get_msg(i_msg_cd)));
END throw;

END excp;
/
