LIBRARY ieee;
LIBRARY work;

USE ieee.std_logic_1164.all; 
USE ieee.numeric_std.all; 
USE work.A0.all;
  
package A0MEM is

  type L1_MEMORY is array (0 to 1023) of WORD; 

end A0MEM;

package body A0MEM is
 
end A0MEM;

LIBRARY ieee;
LIBRARY work;

USE ieee.std_logic_1164.all; 
USE ieee.numeric_std.all;
USE work.UTILS.all;   
USE work.A0MEM.all;
USE work.A0.all;

--------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------

ENTITY A1_MMU IS
  PORT(   
    clock   : in STD_LOGIC;  
    reset   : in STD_LOGIC;
    optype  : in STD_LOGIC_VECTOR(1 downto 0);
    addr1   : in WORD;
    addr2   : in WORD;
    input   : in  STD_LOGIC_VECTOR (31 downto 0);
    output  : out STD_LOGIC_VECTOR (31 downto 0);
    oready  : out STD_LOGIC
    );
END A1_MMU;

ARCHITECTURE RTL OF A1_MMU IS 

  signal memory : L1_MEMORY := (others => x"00000000");
   
begin

  p0 : process(clock,reset)
  
  variable addr : integer;
  
  begin

    if (reset = '1') then
      output <= x"00000000";
      oready <= '1';
      memory <= (others => x"00000000");
    elsif rising_edge(clock) then     

      addr := to_sint(addr1) + to_sint(addr2);
    
      case optype is
      
        when M_LOAD  => output       <= memory(addr);   
      
        when M_STORE => memory(addr) <= input;      
                    
        when others  => output       <= input; 
      
      end case;
     
     oready <= '1';
  
    end if;
    
  end process;

end RTL;