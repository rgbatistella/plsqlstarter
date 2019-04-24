CREATE OR REPLACE PACKAGE timer
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

 Container for simple routines that allow one to time the execution of code
 blocks down to the millisecond level, using DBM_UTILITY.

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
--                               PUBLIC CURSORS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                                PUBLIC TYPES
--------------------------------------------------------------------------------
-- {%skip}
-- timer structure
TYPE tr_timer  IS RECORD
(
   timer_nm VARCHAR2(200),
   tn_start_tm NUMBER,
   tn_stop_tm NUMBER
);
-- {%skip}
-- collection type of timers
TYPE tar_timer IS TABLE OF tr_timer INDEX BY BINARY_INTEGER;

--------------------------------------------------------------------------------
--                 PUBLIC CONSTANTS, VARIABLES, EXCEPTIONS, ETC.
--------------------------------------------------------------------------------
-- {%skip}
-- public collection of timers
gar_timer  tar_timer;

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
elapsed:
 Returns the elapsed time, in seconds, that have passed so far for the named
 timer. If the timer is still running, this number will not remain static. If the
 timer is stopped this number will remain static until the package is cleared 
 from the memory, or a new record is kept for the same-named timer.

%param i_timer_id A name or tag for the timer. Will default if not given.
%param i_time_fmt Time format: s = seconds, ms = milliseconds, cs = centiseconds
------------------------------------------------------------------------------*/
FUNCTION elapsed
(
   i_timer_nm IN VARCHAR2 DEFAULT USER || 'myproc',
   i_time_fmt IN VARCHAR2 DEFAULT 's'
) RETURN NUMBER;


--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------
/**-----------------------------------------------------------------------------
startme/stopme:
 Routines to start and stop and report on a timer. Each timer has a unique name.
 The timer array stores an elapsed time for each one. So within one routine or 
 test, you could have multiple named timers, timers within loops named by the 
 iterations, etc.

 If for some odd reason you feel the need, you can restart a timer by calling
 start with the same name. You may also update a previously stopped timer by
 calling stop again. I don't know why you'd do this, but it's allowed.

 Also, you may call elapsed() while a timer is still running. You will get a 
 greater elapsed time for each call. However, once stop has been called, any 
 further calls to elapsed() will return the same value.

%usage
<code>
   timer.startme('mytimer');
      call_my_proc();
   timer.stopme('mytimer');
   dbms_output.put_line('Run took '||timer.elapsed('mytimer')||' seconds.');
</code>

%param i_timer_nm Any alphanumeric string to uniquely identify a timer.
------------------------------------------------------------------------------*/
PROCEDURE startme(i_timer_nm   IN VARCHAR2 DEFAULT USER||'myproc');
PROCEDURE stopme (i_timer_nm   IN VARCHAR2 DEFAULT USER||'myproc');

END timer;
/
