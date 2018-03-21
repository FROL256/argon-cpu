LIBRARY ieee;
LIBRARY work;

USE ieee.std_logic_1164.all; 
USE ieee.numeric_std.all; 
USE work.A0.all;
  
package A0ALU is


end A0ALU;

package body A0ALU is
 
end A0ALU;

LIBRARY ieee;
LIBRARY work;

USE ieee.std_logic_1164.all; 
USE ieee.numeric_std.all;
USE work.UTILS.all;   
USE work.A0ALU.all;
USE work.A0.all;

--------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------

ENTITY A1_ALU IS
  PORT(   
    clock : in STD_LOGIC;  
    reset : in STD_LOGIC;
    
    code  : in STD_LOGIC_VECTOR(3 downto 0); 
    flags : in Flags;
    xA    : in WORD; 
    xB    : in WORD; 
    
    carryOut : inout std_logic;
    flags_Z  : inout boolean; 
    flags_LT : inout boolean;
    resLow   : inout WORD;
    resHigh  : inout WORD);
    
END A1_ALU;


ARCHITECTURE RTL OF A1_ALU IS 

 
   
begin

  p0 : process(clock,reset)
  
    variable yB     : WORD                  := x"00000000";     -- second op passed to adder
    variable rShift : WORD                  := (others => '0'); -- result of shift ops group
    variable rLog   : WORD                  := (others => '0'); -- result of logic ops group
    variable rAdd   : unsigned(32 downto 0) := (others => '0'); -- result of add   ops group  
    variable rMulc  : WORD                  := (others => '0'); -- result of mult  ops group  
    variable rMul   : unsigned(63 downto 0) := (others => '0'); -- result of true multiplication  
    
    variable carryIn : std_logic := '0'; 
    variable zero    : std_logic := '0'; 
    variable shiftS  : std_logic := '0';    
  
  begin

    if (reset = '1') then
      
      carryOut <= '0';
      flags_Z  <= false; 
      flags_LT <= false;
      resLow   <= (others => '0');
      resHigh  <= (others => '0');
    
    elsif rising_edge(clock) then     

      if code(1) = '1' then  -- sub or sbc  
        yB := not xB;
      else   
        yB := xB;    
      end if;      
        
      carryIn := ToStdLogic( ((code(1 downto 0) = "10") or (code(1 downto 0) = "01" and carryOut = '1')) ); -- SUB or ADC
         
      rAdd := ("0" & unsigned(xA)) + unsigned(yB) + (unsigned'("") & carryIn); -- full 32 bit adder with carry
      carryOut <= rAdd(32);     
         
      zero := not (rAdd(31) or rAdd(30) or rAdd(29) or rAdd(28) or rAdd(27) or rAdd(26) or rAdd(25) or rAdd(24) or rAdd(23) or rAdd(22) or 
                   rAdd(21) or rAdd(20) or rAdd(19) or rAdd(18) or rAdd(17) or rAdd(16) or rAdd(15) or rAdd(14) or rAdd(13) or rAdd(12) or 
                   rAdd(11) or rAdd(10) or rAdd(9)  or rAdd(8)  or rAdd(7)  or rAdd(6)  or rAdd(5)  or rAdd(4)  or rAdd(3)  or rAdd(2)  or rAdd(1) or rAdd(0));
        
      
       
      if flags.CF then
        flags_Z  <= (zero     = '1');
        flags_LT <= (rAdd(31) = '1');  -- sign bit
      else
        flags_Z  <= flags_Z;
        flags_LT <= flags_LT;
      end if;
       
      ----------------------------------------------------------------- mul group  (may be need to optimize, may be not)
        
      if flags.S then 
        rMul := unsigned(signed(xA) * signed(xB));
      else
        rMul := unsigned(xA) * unsigned(xB);           -- full 32 to 64 bit signed/unsigned multiplyer;  
      end if;
       
      resHigh <= std_logic_vector(rMul(63 downto 32)); -- always write this reg, so we must get the hight reg in next command immediately or loose it
       
      case code(1 downto 0) is
        when "00"   => rMulc := resHigh;                             -- constant A_MFH : STD_LOGIC_VECTOR(3 downto 0) := "1100"; -- Move From High
        when "11"   => rMulc := std_logic_vector(rMul(31 downto 0)); -- constant A_MUL : STD_LOGIC_VECTOR(3 downto 0) := "1111"; 
        when others => rMulc := resHigh;                             -- 
      end case;
       
      ----------------------------------------------------------------- logic group
      --
      case code(1 downto 0) is
        when "00"   => rLog := xA and xB;   
        when "01"   => rLog := xA or  xB;
        when "10"   => rLog :=    not xA;
        when others => rLog := xA xor xB;
      end case;  
       
      ----------------------------------------------------------------- shift group
      -- 
      if flags.S then  
        shiftS := xA(31);   -- arithmetic shifts
      else
        shiftS := '0';      -- common shifts
      end if;
       
      case code(1 downto 0) is
        when "01"   => rShift := xA(30 downto 0) & '0';     -- replace with sll
                       if flags.S then 
                         rShift(31) := shiftS;
                       end if;  
        when "10"   => rShift := shiftS & xA(31 downto 1);  -- replace with srl
        when "11"   => rShift := xB;
        when others => rShift := x"00000000";
      end case;
       
      -- get final result   
      --
      case code(3 downto 2) is     
        when "00"   => resLow <= rShift;
        when "01"   => resLow <= std_logic_vector(rAdd(31 downto 0));
        when "10"   => resLow <= rLog;
        when others => resLow <= rMulc;
      end case;   
      -------------------------- alu core -----------------------------  
    
    end if; -- // rising_edge
    
  end process;

end RTL;


