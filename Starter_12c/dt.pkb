CREATE OR REPLACE PACKAGE BODY dt
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
--gc_pkg_nm CONSTANT user_source.name%TYPE := 'dt';

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
FUNCTION get_highdt RETURN DATE IS
BEGIN

   RETURN TO_DATE('12/31/9999', 'MM/DD/YYYY');
   
END get_highdt;

--------------------------------------------------------------------------------
FUNCTION get_sysdt RETURN DATE IS
BEGIN
   RETURN TRUNC(SYSDATE);
END get_sysdt;

--------------------------------------------------------------------------------
FUNCTION get_sysdtm RETURN DATE IS
BEGIN
   RETURN SYSDATE;
END get_sysdtm;

--------------------------------------------------------------------------------
FUNCTION get_systs RETURN TIMESTAMP IS
BEGIN
   RETURN SYSTIMESTAMP;
END get_systs;

--------------------------------------------------------------------------------
FUNCTION get_day_name(i_num IN NUMBER) RETURN VARCHAR2 IS
   l_day VARCHAR2(9);
BEGIN
   IF i_num = 1 THEN
      l_day := 'Sunday';
   ELSIF i_num = 2 THEN
      l_day := 'Monday';
   ELSIF i_num = 3 THEN
      l_day := 'Tuesday';
   ELSIF i_num = 4 THEN
      l_day := 'Wednesday';
   ELSIF i_num = 5 THEN
      l_day := 'Thursday';
   ELSIF i_num = 6 THEN
      l_day := 'Friday';
   ELSIF i_num = 7 THEN
      l_day := 'Saturday';
   END IF;
   
   RETURN l_day;
   
END get_day_name;

--------------------------------------------------------------------------------
FUNCTION minutes_to_dhm(i_mnts IN NUMBER) RETURN VARCHAR2 AS
   l_days      PLS_INTEGER;
   l_hours     PLS_INTEGER;
   l_carryover NUMBER := 0;
BEGIN
   IF (i_mnts IS NULL) THEN
      RETURN NULL;
   END IF;
   l_days      := TRUNC(i_mnts / minutes_per_day); --gives any days involved
   l_carryover := MOD(i_mnts, minutes_per_day); --strips days from remaining hours
   l_hours     := TRUNC(l_carryover / 60); --gives any hours involved
   l_carryover := ROUND(MOD(l_carryover, 60)); --strips hours from remaining minutes
   
   RETURN TO_CHAR(l_days) || ':' || TO_CHAR(l_hours) || ':' || TO_CHAR(l_carryover,'FM09');

END minutes_to_dhm;

--------------------------------------------------------------------------------
FUNCTION minutes_to_hm(i_mnts IN NUMBER) RETURN VARCHAR2 AS
   l_hours     PLS_INTEGER;
   l_carryover NUMBER := 0;
BEGIN
   IF (i_mnts IS NULL) THEN
      RETURN NULL;
   END IF;
   l_hours     := TRUNC(i_mnts / 60); --gives any hours involved
   l_carryover := ROUND(MOD(i_mnts, 60)); --strips hours from remaining minutes
   
   RETURN TO_CHAR(l_hours) || ':' || TO_CHAR(l_carryover, 'FM09');

END minutes_to_hm;

--------------------------------------------------------------------------------
FUNCTION get_time_diff
(
   i_old_dtm  IN DATE,
   i_curr_dtm IN DATE DEFAULT SYSDATE,
   i_tm_uom   IN VARCHAR2 DEFAULT 'hour'
) RETURN NUMBER DETERMINISTIC IS
   l_curr_dtm DATE;
   l_diff      NUMBER;
BEGIN
   IF (i_tm_uom NOT IN ('second','minute','hour','day','week','year')) THEN
      raise_application_error(-20000,'ERROR: Invalid i_tm_uom ['||i_tm_uom||
         ']. UOM parameter supports second, minute, hour, day, week and year.');
   END IF;
   
   IF (i_old_dtm IS NULL) THEN
      -- can't determine age if we don't have a start point, return no answer
      raise_application_error(-20000,'ERROR: i_old_dtm is NULL. Cannot determine difference without a start point.');
   END IF;
   
   l_curr_dtm := NVL(i_curr_dtm, SYSDATE);
   SELECT (l_curr_dtm - i_old_dtm) * DECODE(i_tm_uom,
                                            'day',1,
                                            'hour',24,
                                            'minute',1440,
                                            'second',86400,
                                            'week',(1/7),
                                            'year',(1/365)
                                            ) age
     INTO l_diff
     FROM dual;
      
   RETURN l_diff;
   
END get_time_diff;

--------------------------------------------------------------------------------
FUNCTION get_time_diff_str
(
   i_old_dtm  IN DATE,
   i_curr_dtm IN DATE DEFAULT SYSDATE,
   i_tm_uom   IN VARCHAR2 DEFAULT 'hour'
) RETURN VARCHAR2 DETERMINISTIC IS
   l_suffix VARCHAR2(10);
BEGIN
   IF (i_tm_uom = 'hour') THEN
      l_suffix := 'hr';
   ELSIF (i_tm_uom = 'day') THEN
      l_suffix := 'dy';
   ELSIF (i_tm_uom = 'minute') THEN
      l_suffix := 'mnt';
   ELSIF (i_tm_uom = 'second') THEN
      l_suffix := 'sec';
   ELSIF (i_tm_uom = 'week') THEN
      l_suffix := 'wk';
   ELSIF (i_tm_uom = 'year') THEN
      l_suffix := 'yr';
   ELSE
      l_suffix := 'NA';
   END IF;
   
   IF (i_tm_uom = 'hm') THEN
      RETURN minutes_to_hm(get_time_diff(i_old_dtm, i_curr_dtm, 'minute'));
   ELSIF (i_tm_uom = 'dhm') THEN
      RETURN minutes_to_dhm(get_time_diff(i_old_dtm, i_curr_dtm, 'minute'));
   ELSE
      RETURN TO_CHAR(get_time_diff(i_old_dtm, i_curr_dtm, i_tm_uom),
                     'FM999G999G999G990D09') || ' ' || l_suffix;
   END IF;
END get_time_diff_str;

--------------------------------------------------------------------------------
FUNCTION trunc_dt
(
   i_dtm         IN DATE,
   i_trunc_floor IN PLS_INTEGER
) RETURN DATE IS
   l_factor NUMBER;
BEGIN
   IF (i_dtm IS NULL) THEN
      RETURN NULL;
   ELSE
      l_factor := (i_trunc_floor / minutes_per_day); -- gives us fraction of a day
      
      -- the following rounds a date down to the nearest time increment matching
      -- the given truncation floor.
      RETURN(TRUNC(i_dtm) +
             TRUNC((i_dtm - TRUNC(i_dtm)) / l_factor, 0) * l_factor);
   END IF;
END trunc_dt;

--------------------------------------------------------------------------------
FUNCTION dt_to_epoch
(
   i_dt          IN DATE
) RETURN NUMBER
IS
BEGIN
   RETURN (i_dt - UNIX_EPOCH) * SECONDS_PER_DAY;
END dt_to_epoch;

--------------------------------------------------------------------------------
FUNCTION epoch_to_dt
(
  i_epoch_num    IN NUMBER
) RETURN DATE
IS
BEGIN
   RETURN i_epoch_num /(SECONDS_PER_DAY) + UNIX_EPOCH;
END epoch_to_dt;

END dt;
/
