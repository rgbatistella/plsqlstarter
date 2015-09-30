PL/SQL Developer Test script 3.0
5
begin
  -- Call the function
  :result := dt.trunc_dt(i_dtm => :i_dtm,
                         i_trunc_floor => :i_trunc_floor);
end;
3
result
0
12
i_dtm
1
2008Mar10 02:20:00
12
i_trunc_floor
1
30
3
0
