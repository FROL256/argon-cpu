LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.numeric_std.all;		
use ieee.numeric_bit.all;

package ATESTS is			
  
  function TestClocks(testId : in integer) return integer;
  function CheckTest(testId : in integer; R0 : integer; R1 : integer; R2 : integer) return boolean;
 
end ATESTS;

package body ATESTS is
  	
  function TestClocks(testId : in integer) return integer is
  begin 
	  
	case testId is 
		
	  when 0      => return 50; 
      when others => return 50;
		
    end case;
	  
  end TestClocks;
	
	
  function CheckTest(testId : in integer; R0 : integer; R1 : integer; R2 : integer) return boolean is
  begin	
	
	case testId is 
		
	  when 1      => return ((R0 = 5) and (R1 = 3) and (R2 = 2)); 
	  when 2      => return ((R0 = 3) and (R1 = 3) and (R2 = 10));
	  when 3      => return ((R0 = 7) and (R1 = 3) and (R2 = 2));
	  when 4      => return ((R0 = 7) and (R1 = 0) and (R2 = 0));
	  when 5      => return ((R0 = 6) and (R1 = 3) and (R2 = 2));
	  when 6      => return ((R0 = 8) and (R1 = 4) and (R2 = 5));
	  when 7      => return ((R0 = 20) and (R1 = 6) and (R2 = 7));
	  when 8      => return ((R0 = 1) and (R1 = -5) and (R2 = 0)); -- not sure about this test	
	  when 9      => return ((R0 = 1) and (R1 = 4) and (R2 = 0));  -- not sure about this test
	  when 10     => return ((R0 = 2) and (R1 = 271) and (R2 = 255));	 
	  
      when others => return false;
		
    end case;
	
  end CheckTest;
 
  
  
end ATESTS;




