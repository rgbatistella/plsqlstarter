PL/SQL Developer Test script 3.0
5
begin
  -- Call the procedure
  excp.throw(i_msg_cd => 'Row Lock Held',
             i_msg => msgs.fill_msg('Row Lock Held','Bogus Lock'));
end;
0
0
