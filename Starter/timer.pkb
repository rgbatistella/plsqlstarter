CREATE OR REPLACE PACKAGE BODY timer
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
--gc_pkg_nm CONSTANT user_source.name%TYPE := 'timer';

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
find_match:
 Runs through the collection of timers until it finds the one that matches in
 name.
------------------------------------------------------------------------------*/
FUNCTION find_match(i_timer_nm   IN VARCHAR2) RETURN PLS_INTEGER
IS
BEGIN
   FOR i IN 1..gar_timer.COUNT LOOP
      IF (gar_timer(i).timer_nm = i_timer_nm) THEN
         RETURN i;
      END IF;
   END LOOP;
   RETURN NULL;
END find_match;

--------------------------------------------------------------------------------
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
FUNCTION elapsed(
   i_timer_nm IN VARCHAR2 DEFAULT USER || 'myproc',
   i_time_fmt IN VARCHAR2 DEFAULT 's'
) RETURN NUMBER
IS
   l_idx   PLS_INTEGER := 0;
   l_tm    NUMBER := 0;
   l_multiplier NUMBER := 0;
BEGIN
   IF (i_time_fmt IS NULL OR LOWER(i_time_fmt) NOT IN ('s','ms','cs')) THEN
      raise_application_error(-20000,
         'timer.elapsed: only supports time formats s (seconds, default), ms (milliseconds) and cs (centiseconds)');
   END IF;
   
   -- determine the index at which the read will take place
   l_idx := find_match(i_timer_nm);
   IF (l_idx IS NULL) THEN
      raise_application_error(-20000, 'timer.elapsed: Can''t find timer named '||i_timer_nm);
      l_tm := NULL;
   ELSE
      l_multiplier := CASE i_time_fmt WHEN 's' THEN (1/100) WHEN 'ms' THEN 10 WHEN 'cs' THEN 1 END;
      IF (gar_timer(l_idx).tn_stop_tm IS NULL) THEN
         -- timer hasn't been officially stopped, so report how much has elapsed so far
         l_tm := (dbms_utility.get_time - gar_timer(l_idx).tn_start_tm)*l_multiplier;
      ELSE
         l_tm := (gar_timer(l_idx).tn_stop_tm - gar_timer(l_idx).tn_start_tm)*l_multiplier;
      END IF;
   END IF;
   RETURN l_tm;
END elapsed;

--------------------------------------------------------------------------------
PROCEDURE startme(i_timer_nm   IN VARCHAR2 DEFAULT USER||'myproc')
IS
   l_idx   PLS_INTEGER := 0;
BEGIN
   -- determine the index at which the insertion will take place
   l_idx := NVL(find_match(i_timer_nm),gar_timer.COUNT+1);
   -- now insert the data
   gar_timer(l_idx).timer_nm := i_timer_nm;
   gar_timer(l_idx).tn_start_tm := dbms_utility.get_time;
END startme;

--------------------------------------------------------------------------------
PROCEDURE stopme(i_timer_nm    IN VARCHAR2 DEFAULT USER||'myproc')
IS
   l_idx   PLS_INTEGER := 0;
BEGIN
   -- determine the index at which the update will take place
   l_idx := find_match(i_timer_nm);
   IF (l_idx IS NULL) THEN
      raise_application_error(-20000, 'timer.stopme: Can''t find timer named '||i_timer_nm);
   ELSE
      -- now insert the data
      gar_timer(l_idx).tn_stop_tm := dbms_utility.get_time;
   END IF;
END stopme;

END timer;
/
