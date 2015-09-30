CREATE OR REPLACE PACKAGE dt
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

 Contains constants and routines for working with date values.

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      1997Dec30 Creation
bcoulam      2008Sep23 Added Unix-style "epoch" functions.

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

--------------------------------------------------------------------------------
--                 PUBLIC CONSTANTS, VARIABLES, EXCEPTIONS, ETC.
--------------------------------------------------------------------------------
-- more readable and less prone to typos, these will never change
SECONDS_PER_DAY  CONSTANT PLS_INTEGER := 86400;
SECONDS_PER_HOUR CONSTANT PLS_INTEGER := 3600;
SECONDS_PER_MIN  CONSTANT PLS_INTEGER := 60;
MINUTES_PER_DAY  CONSTANT PLS_INTEGER := 1440;
HOURS_PER_DAY    CONSTANT PLS_INTEGER := 24;
DAYS_PER_WEEK    CONSTANT PLS_INTEGER := 7;
MONTHS_PER_YEAR  CONSTANT PLS_INTEGER := 12;
DAYS_PER_YEAR    CONSTANT PLS_INTEGER := 365;

-- time portions for complex date arithmetic
ONE_SECOND CONSTANT NUMBER(9,9) := (1/SECONDS_PER_DAY);
ONE_MINUTE CONSTANT NUMBER(9,9) := (1/MINUTES_PER_DAY);
ONE_HOUR   CONSTANT NUMBER(9,9) := (1/24);

FIVE_MINUTES    CONSTANT NUMBER(9,9) := (5/MINUTES_PER_DAY);
TEN_MINUTES     CONSTANT NUMBER(9,9) := (10/MINUTES_PER_DAY);
FIFTEEN_MINUTES CONSTANT NUMBER(9,9) := (15/MINUTES_PER_DAY);
THIRTY_MINUTES  CONSTANT NUMBER(9,9) := (30/MINUTES_PER_DAY);

-- date/time mask constants
BATCH_DT_MASK	   CONSTANT VARCHAR2(30)	:= 'YYYYMMDD';
Y2K_BATCH_DT_MASK	CONSTANT VARCHAR2(30)	:= 'RRMMDD';
Y2K_DT_MASK	      CONSTANT VARCHAR2(30)	:= 'MM/DD/RR';
DT_MASK	         CONSTANT VARCHAR2(20) := 'MM/DD/RRRR';
DTM_MASK          CONSTANT VARCHAR2(22) := 'MM/DD/RRRR HH24:MI:SS';
SORTABLE_DTM_MASK CONSTANT VARCHAR2(20) := 'YYYYMonDD HH24:MI:SS';
TM_MASK           CONSTANT VARCHAR2(10) := 'HH24:MI:SS';

-- Unix epoch
UNIX_EPOCH        CONSTANT DATE := TO_DATE('1970Jan01','YYYYMonDD');

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
get_highdt:
 Returns the high date to be used by the application. There is not
 a corresponding get_highdtm since the maximum date currently allowed
 by Oracle (12/31/9999) returns with no time portion, just the date.
------------------------------------------------------------------------------*/
FUNCTION get_highdt RETURN DATE;    

/**-----------------------------------------------------------------------------
get_sysdt:
 Returns the current date (TRUNC'ed of the time portion)
------------------------------------------------------------------------------*/
FUNCTION get_sysdt RETURN DATE;

/**-----------------------------------------------------------------------------
get_sysdtm:
 Returns the current date and time
------------------------------------------------------------------------------*/
FUNCTION get_sysdtm RETURN DATE;

/**-----------------------------------------------------------------------------
get_systs:
 Returns the current date and time
------------------------------------------------------------------------------*/
FUNCTION get_systs RETURN TIMESTAMP;
  
/**-----------------------------------------------------------------------------
get_day_name:
 Given the day of the week (as an integer), returns the name of the day of the
 week.

%param    i_num - the number of the day of the week.
------------------------------------------------------------------------------*/
FUNCTION get_day_name(i_num	IN NUMBER)  RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
minutes_to_dhm and minutes_to_hm:
 These functions take a measure in minutes and return a string
 formatted in
 dhm -> dd:hh:mm format, e.g. 6:2:03 means 6 days, 2 hours and 3 minutes
 hm -> hh:mm format, e.g. 0:34 means 0 hours and 34 minutes

%param    i_mnts - Number of minutes to format, in integer form
------------------------------------------------------------------------------*/
FUNCTION minutes_to_dhm (i_mnts IN NUMBER) RETURN VARCHAR2;

FUNCTION minutes_to_hm (i_mnts IN NUMBER) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
get_time_diff:
 Returns the number of time units between two dates. The time units are based 
 upon the unit of measure specified by the caller. The result could be fractional,
 in which case the result has full precision. If you don't need so many digits
 of precision, use ROUND or TRUNC or TO_CHAR with a numeric format model to 
 reduce the number of digits to the right of the decimal.

%return
 Returns an integer, based upon the desired time period, e.g.
 3 [weeks]
 10 [days]
 45 [minutes]
 ...and so forth

%param    i_old_dtm - The begin date of the period to measure
%param    i_curr_dtm - The end date of the period to measure
%param    i_tm_uom - Time-based Unit of Measure. Acceptable values are:
                     'day','hour','minute','second','week','year'
------------------------------------------------------------------------------*/
FUNCTION get_time_diff
(
   i_old_dtm  IN DATE,
   i_curr_dtm IN DATE DEFAULT SYSDATE,
   i_tm_uom   IN VARCHAR2 DEFAULT 'hour'
) RETURN NUMBER;

/**-----------------------------------------------------------------------------
get_time_diff_str:
 Returns the period of time between two dates suffixed with a given unit of 
 measure. Calls upon get_time_diff with the same interface. If the uom value is
 "hm" or "dhm" it means to calculate the difference in terms of minutes, but 
 return the age formatted, as in days:hours;minutes, e.g. a 192 minute 
 difference, or age, would return  3:12 or 0:3:12, depending on the format chosen.

Returns a string, based upon the given time period, e.g. "3 hr" or ".15 dy" "650 sec"

%param    i_old_dtm The begin date of the period to measure
%param    i_curr_dtm The end date of the period to measure. Defaults to now.
%param    i_tm_uom Time-based Unit of Measure. Acceptable values are:
                  'second','minute','hour','day','week','year','dhm','hm'
------------------------------------------------------------------------------*/
FUNCTION get_time_diff_str
(
   i_old_dtm  IN DATE,
   i_curr_dtm IN DATE DEFAULT SYSDATE,
   i_tm_uom   IN VARCHAR2 DEFAULT 'hour'
) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
trunc_dt:
 The following rounds a date down to the nearest time increment matching
 the given truncation floor. For example, if the requested trunc floor is
 a 5 minute increment, then a 1999Sep29 16:47:26 date will be returned
 as 1999Sep29 16:45:00, so too will 16:49:59 be returned as 16:45:00 since
 it is being rounded down to the latest 5 minute increment.

%param    i_dtm  Date to truncate
%param    i_trunc_floor  A time period in minutes to which we want to round the
                         date down to. This enables events, queries and reports
                         to be grouped based on the time period passed into this
                         parameter, i.e. these records were produced in this 
                         5 or 10 or 20 or 30 or 60 minute period.
------------------------------------------------------------------------------*/
FUNCTION trunc_dt
(
   i_dtm         IN DATE,
   i_trunc_floor IN PLS_INTEGER
) RETURN DATE;


/**-----------------------------------------------------------------------------
dt_to_epoch:
 Converts an Oracle DATE value to the Unix "seconds from epoch" value, with the
 epoch defined as Jan 01, 1970.
------------------------------------------------------------------------------*/
FUNCTION dt_to_epoch
(
   i_dt          IN DATE
) RETURN NUMBER;

/**-----------------------------------------------------------------------------
epoch_to_dt:
 Converts a Unix "seconds from epoch" numeric value to an Oracle DATE.
------------------------------------------------------------------------------*/
FUNCTION epoch_to_dt
(
  i_epoch_num    IN NUMBER
) RETURN DATE;

--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------

END dt;
/
