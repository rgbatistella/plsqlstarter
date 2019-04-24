SET SERVEROUTPUT ON SIZE 1000000
DECLARE
   l_large_msg CLOB;
   l_large_msg_blob BLOB;
BEGIN
   dbms_lob.createtemporary(l_large_msg, TRUE);

   l_large_msg := ' KEY WEST, Fla. - Tourists jumped on the last plane out of town, store owners shuttered their doors and palm trees bent in gusty winds as Tropical Storm Fay began to bear down on the Florida Keys Monday after killing at least eight people in the Carribean.
ADVERTISEMENT

Roughly 25,000 tourists had evacuated, Monroe County Mayor Mario Di Gennaro said, but some bars and restaurants were doing business, even if crowds were considerably thinner. Despite warnings the storm could strengthen, some hurricane-hardened residents refused to leave.

Willie Dykes, 58, and friend Essy Pastrana, 48, live on a sailboat in Key West, and said they weren''t going anywhere. The pair was filling up gas cans Monday morning and buying supplies like food, water and whiskey.

"We''re gonna ride it out," Dykes said, his fluffy white beard blowing sideways in the wind. "We''re not worried about it. We''ve seen this movie before."

Fay, the sixth named storm of the 2008 Atlantic season, left at least five people dead in Haiti and the Dominican Republic. In Haiti, a bus overturned while trying to drive across a river surging with rain, creating fears that up to 30 people were dead. U.N. police spokesman Fred Blaise said later that 41 people escaped, but peacekeepers saw the bodies of two infants who drowned in the the Riviere Glace. Peacekeepers also found the body of a man who drowned in the river but was not on the bus, he said.

Forecasters said Fay is expected to near hurricane strength, which starts at windspeeds of 74 mph, when it reaches the Keys later Monday. Aside from wind damage, most of the islands sit at sea level and could face some limited flooding from Fay''s storm surge.

The exact track is not clear but the storm is expected to hit the Keys first and then sweep up the western coast of Florida, forecasters said. It could strengthen into a Category 1 storm after it moves past the Keys.

Anywhere from 4 to 10 inches of rain are possible, so flooding is a threat even far from where the center comes ashore, said Stacy Stewart, a senior hurricane specialist at the National Hurricane Center.

"We don''t want people to focus on the exact track. This is a broad, really diffuse storm. All the Florida Keys and all the Florida peninsula are going to feel the effects of this storm, no matter where the center makes landfall," he said.

Gov. Charlie Crist said at a news conference in Tallahassee that 500 National Guard troops have been activated but will not be dispatched until it''s clear when and where they are needed. Although Fay does not appear to be as powerful as other recent Florida storms, Crist said people shouldn''t be complacent.

"We want every, every Floridian and guest to be a survivor," the governor said. "I know it''s only a tropical storm but we take it seriously."

Traffic leaving Key West and the Lower Keys remained light but steady. Monroe County Sheriff Rick Roth said the 110-mile, mostly two-lane Overseas Highway would likely remain open during and after the storm, but he urged people not to travel once Fay hits.

The last plane left Key West International Airport at about 9:30 a.m. with 19 people aboard, headed to Fort Lauderdale. The airport shut down a half hour later. The last Greyhound bus also left Key West Monday morning nearly empty with just 15 people aboard.

A hurricane watch was in effect for most of the Keys and along Florida''s west coast. A tropical storm warning was issued for Florida''s east coast from Sebastian Inlet southward and along Florida''s west coast from Bonita Beach southward, including Lake Okeechobee.

Marathon Home Depot assistant manager Denis Lee said it seemed like a normal Monday despite the approaching storm.

"Everybody seems to be acting like this is a non-event," Lee said.

Just before 2 p.m. EDT Monday, the storm''s center was approaching Key West across the Florida Straits between Cuba and the Keys. The center was about 20 miles southeast of Key West and the storm was moving toward the north-northwest near 14 mph.

Maximum sustained wind speeds were near 60 mph with higher gusts, and the storm was expected to strengthen over the next 24 hours to hurricane strength.

In Crawford, Texas, White House deputy press secretary Gordon Johndroe said officials were evaluating whether it will still be possible for President Bush to make a scheduled trip on Wednesday to speak to the Veterans of Foreign Wars national convention in Orlando.

Republican presidential candidate John McCain and Democratic opponent Barack Obama also are scheduled to speak.

Key West was last seriously affected by a hurricane in 2005, when Category 3 Wilma sped past. The town escaped widespread wind damage, but a storm surge flooded hundreds of homes and some businesses. The deadliest storm to hit the island was a Category 4 hurricane in 1919 that killed up to 900 people, many of them offshore on ships that sank. 
';

   dbms_output.put_line('Length of l_large_msg is '||dbms_lob.getlength(l_large_msg)); 
   l_large_msg_blob := util.convert_clob_to_blob(l_large_msg);
   
   dbms_output.put_line('Length of l_large_msg_blob is '||dbms_lob.getlength(l_large_msg_blob)); 
      
END;
/
