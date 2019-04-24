PL/SQL Developer Test script 3.0
85
DECLARE
  l_str    VARCHAR2(32767) := 'Four years after her big breakthrough with the smash hit ”Satellites” September continues to rule the international charts. ”Cry for you” went top 10 in more than 15 countries and kept the #1 position at Billboard Dance Radio Airplay for three weeks. In the UK the single sold 250 000 copies, worldwide close to 1.5 million. Ever since her debut single “La la la (Never give it up)” in 2003, Swedish singer and dancing queen Petra Marklund has worked together with songwriter and producer Jonas van der Burg and the two songwriters Niclas van der Burg and Anoo Bhagavan. Together they have continued to follow-up one hit with another without repeating themselves and without losing their audience. September has become a reliable provider of the catchiest pop and dance tunes you can imagine.

The four of us have stuck to the formula, which makes it easier for the audience to understand what September is about. We love to work with each other. Of course there are conflicts sometimes, but in the end we are still a team”, she explains.

Today September is one of Sweden’s biggest musical exports. Earlier this year she was nominated for the government’s music export prize together with Björn and Benny (ABBA). The international success means that Petra spends a lot of time in airports, usually far away from home. It is a lifestyle that does not fit everyone, but for her it is the only life she knows – and she loves it. When other artists move to the country to have some rest in-between shows and recordings Petra will spend the following year in London. With all the travelling it is more convenient to live in the UK, but that is not the only reason she is packing her bags.';

  l_result VARCHAR2(32767);
BEGIN

  l_result := str.format_to_width(i_str => l_str,
                         i_width => 120,
                         i_allow_wrap => 'N');
  dbms_output.put_line('*** Output at 120 chars wide, wrap off ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;

  l_result := str.format_to_width(i_str => l_str,
                         i_width => 80,
                         i_allow_wrap => 'N');
  dbms_output.put_line('*** Output at 80 chars wide, wrap off ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;

  l_result := str.format_to_width(i_str => l_str,
                         i_width => 40,
                         i_allow_wrap => 'N');
  dbms_output.put_line('*** Output at 40 chars wide, wrap off ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;

  l_result := str.format_to_width(i_str => l_str,
                         i_width => 120,
                         i_allow_wrap => 'Y');
  dbms_output.put_line('*** Output at 120 chars wide, wrap on ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;

  l_result := str.format_to_width(i_str => l_str,
                         i_width => 80,
                         i_allow_wrap => 'Y');
  dbms_output.put_line('*** Output at 80 chars wide, wrap on ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;

  l_result := str.format_to_width(i_str => l_str,
                         i_width => 40,
                         i_allow_wrap => 'Y');
  dbms_output.put_line('*** Output at 40 chars wide, wrap on ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;

  l_result := str.format_to_width(i_str => '',
                         i_width => 50,
                         i_allow_wrap => 'N');
  dbms_output.put_line('*** NULL INPUT ***');
  dbms_output.put_line('>'||l_result||'<');
  dbms_output.new_line;
  
  l_result := str.format_to_width(i_str => 'Hello World',
                         i_width => 50,
                         i_allow_wrap => 'N');
  dbms_output.put_line('*** Short input (shorter than requested width) ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;
  
  l_result := str.format_to_width(i_str => 'This is my one line sentence, with an odd little
carriage return right between "little" and "carriage."
',
                         i_width => 20,
                         i_allow_wrap => 'N');
  dbms_output.put_line('*** Really short width ***');
  dbms_output.put_line(l_result);
  dbms_output.new_line;
  
  l_result := str.format_to_width(i_str => 'This is my one line sentence, with an odd little
carriage return right between "little" and "carriage."
',
                         i_width => 120,
                         i_allow_wrap => 'N');
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
