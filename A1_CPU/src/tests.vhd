LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.numeric_std.all;		
use ieee.numeric_bit.all;

package ATESTS is			

  function CheckTest(testId : in integer; R0 : integer; R1 : integer; R2 : integer) return boolean;
 
end ATESTS;

package body ATESTS is
  
  function CheckTest(testId : in integer; R0 : integer; R1 : integer; R2 : integer) return boolean is
  begin	
	
	case testId is 
		
	  when 0      => return ((R0 = 5) and (R1 = 3) and (R2 = 2)); 
	  when 1      => return ((R0 = 3) and (R1 = 3) and (R2 = 10));
	  
	  
      when others => return false;
		
    end case;
	
  end CheckTest;
 
  
  
end ATESTS;




