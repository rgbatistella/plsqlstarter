PL/SQL Developer Test script 3.0
109
DECLARE
  l_result VARCHAR2(32767);
BEGIN

  l_result := str.format_to_width(i_str => 'We are going to need to save a currency/country code combination in IMOS_MISSIONARY_TRANSACTION to allow for the editing of one-time missionary support payments to change payment method (JPMC, CHECK, LOCAL CHECK). I am putting in a work story for Bill to add columns for this. To start, this will *only* be used to determine the payment methods allowed for the org setup associated with the one time support payment.

In the IMOS_MISTRAN_ACCT_DISTRIBUTION table (which has a many-to-one relationship to IMOS_MISSIONARY_TRANSACTION), we have a CURRENCY column. What I would like to know is if this column would now be unnecessary. Can a SupportTransaction ever be generated/created that will have distribution lines of different currencies?

If not, then I think I should start using the currency from the IMOS_MISSIONARY_TRANSACTION table and we drop the currency column from IMOS_MISTRAN_ACCT_DISTRIBUTION since it is superfluous. Otherwise, we can leave it as is and nothing should be affected.
',
                         i_width => 120,
                         i_allow_wrap => FALSE);
  dbms_output.put_line('*** Output at 120 chars wide, wrap off ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;

  l_result := str.format_to_width(i_str => 'We are going to need to save a currency/country code combination in IMOS_MISSIONARY_TRANSACTION to allow for the editing of one-time missionary support payments to change payment method (JPMC, CHECK, LOCAL CHECK). I am putting in a work story for Bill to add columns for this. To start, this will *only* be used to determine the payment methods allowed for the org setup associated with the one time support payment.

In the IMOS_MISTRAN_ACCT_DISTRIBUTION table (which has a many-to-one relationship to IMOS_MISSIONARY_TRANSACTION), we have a CURRENCY column. What I would like to know is if this column would now be unnecessary. Can a SupportTransaction ever be generated/created that will have distribution lines of different currencies?

If not, then I think I should start using the currency from the IMOS_MISSIONARY_TRANSACTION table and we drop the currency column from IMOS_MISTRAN_ACCT_DISTRIBUTION since it is superfluous. Otherwise, we can leave it as is and nothing should be affected.
',
                         i_width => 80,
                         i_allow_wrap => FALSE);
  dbms_output.put_line('*** Output at 80 chars wide, wrap off ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;

  l_result := str.format_to_width(i_str => 'We are going to need to save a currency/country code combination in IMOS_MISSIONARY_TRANSACTION to allow for the editing of one-time missionary support payments to change payment method (JPMC, CHECK, LOCAL CHECK). I am putting in a work story for Bill to add columns for this. To start, this will *only* be used to determine the payment methods allowed for the org setup associated with the one time support payment.

In the IMOS_MISTRAN_ACCT_DISTRIBUTION table (which has a many-to-one relationship to IMOS_MISSIONARY_TRANSACTION), we have a CURRENCY column. What I would like to know is if this column would now be unnecessary. Can a SupportTransaction ever be generated/created that will have distribution lines of different currencies?

If not, then I think I should start using the currency from the IMOS_MISSIONARY_TRANSACTION table and we drop the currency column from IMOS_MISTRAN_ACCT_DISTRIBUTION since it is superfluous. Otherwise, we can leave it as is and nothing should be affected.
',
                         i_width => 40,
                         i_allow_wrap => FALSE);
  dbms_output.put_line('*** Output at 40 chars wide, wrap off ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;

  l_result := str.format_to_width(i_str => 'We are going to need to save a currency/country code combination in IMOS_MISSIONARY_TRANSACTION to allow for the editing of one-time missionary support payments to change payment method (JPMC, CHECK, LOCAL CHECK). I am putting in a work story for Bill to add columns for this. To start, this will *only* be used to determine the payment methods allowed for the org setup associated with the one time support payment.

In the IMOS_MISTRAN_ACCT_DISTRIBUTION table (which has a many-to-one relationship to IMOS_MISSIONARY_TRANSACTION), we have a CURRENCY column. What I would like to know is if this column would now be unnecessary. Can a SupportTransaction ever be generated/created that will have distribution lines of different currencies?

If not, then I think I should start using the currency from the IMOS_MISSIONARY_TRANSACTION table and we drop the currency column from IMOS_MISTRAN_ACCT_DISTRIBUTION since it is superfluous. Otherwise, we can leave it as is and nothing should be affected.
',
                         i_width => 120,
                         i_allow_wrap => TRUE);
  dbms_output.put_line('*** Output at 120 chars wide, wrap on ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;

  l_result := str.format_to_width(i_str => 'We are going to need to save a currency/country code combination in IMOS_MISSIONARY_TRANSACTION to allow for the editing of one-time missionary support payments to change payment method (JPMC, CHECK, LOCAL CHECK). I am putting in a work story for Bill to add columns for this. To start, this will *only* be used to determine the payment methods allowed for the org setup associated with the one time support payment.

In the IMOS_MISTRAN_ACCT_DISTRIBUTION table (which has a many-to-one relationship to IMOS_MISSIONARY_TRANSACTION), we have a CURRENCY column. What I would like to know is if this column would now be unnecessary. Can a SupportTransaction ever be generated/created that will have distribution lines of different currencies?

If not, then I think I should start using the currency from the IMOS_MISSIONARY_TRANSACTION table and we drop the currency column from IMOS_MISTRAN_ACCT_DISTRIBUTION since it is superfluous. Otherwise, we can leave it as is and nothing should be affected.
',
                         i_width => 80,
                         i_allow_wrap => TRUE);
  dbms_output.put_line('*** Output at 80 chars wide, wrap on ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;

  l_result := str.format_to_width(i_str => 'We are going to need to save a currency/country code combination in IMOS_MISSIONARY_TRANSACTION to allow for the editing of one-time missionary support payments to change payment method (JPMC, CHECK, LOCAL CHECK). I am putting in a work story for Bill to add columns for this. To start, this will *only* be used to determine the payment methods allowed for the org setup associated with the one time support payment.

In the IMOS_MISTRAN_ACCT_DISTRIBUTION table (which has a many-to-one relationship to IMOS_MISSIONARY_TRANSACTION), we have a CURRENCY column. What I would like to know is if this column would now be unnecessary. Can a SupportTransaction ever be generated/created that will have distribution lines of different currencies?

If not, then I think I should start using the currency from the IMOS_MISSIONARY_TRANSACTION table and we drop the currency column from IMOS_MISTRAN_ACCT_DISTRIBUTION since it is superfluous. Otherwise, we can leave it as is and nothing should be affected.
',
                         i_width => 40,
                         i_allow_wrap => TRUE);
  dbms_output.put_line('*** Output at 40 chars wide, wrap on ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;

  l_result := str.format_to_width(i_str => '',
                         i_width => 50,
                         i_allow_wrap => FALSE);
  dbms_output.put_line('*** NULL INPUT ***');
  dbms_output.put_line('>'||l_result||'<');
  dbms_output.new_line;
  
  l_result := str.format_to_width(i_str => 'Hello World',
                         i_width => 50,
                         i_allow_wrap => FALSE);
  dbms_output.put_line('*** Short input (shorter than requested width) ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;
  
  l_result := str.format_to_width(i_str => 'This is my one line sentence, with an odd little
carriage return right between "little" and "carriage."
',
                         i_width => 20,
                         i_allow_wrap => FALSE);
  dbms_output.put_line('*** Really short width ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;
  
  l_result := str.format_to_width(i_str => 'This is my one line sentence, with an odd little
carriage return right between "little" and "carriage."
',
                         i_width => 120,
                         i_allow_wrap => FALSE);
  dbms_output.put_line('*** Output at 120 chars wide ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;
  
END;
0
6
l_curr_pos
l_width
l_next_para
l_next_space
l_next_dash
l_piece
