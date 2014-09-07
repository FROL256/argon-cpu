LIBRARY ieee;
use ieee.numeric_bit.all;

package UTILS is
  function to_uint(bits: BIT_VECTOR) return integer;
  function to_uint(bits: ieee.std_logic_1164.STD_LOGIC_VECTOR) return integer;
  function to_sint(bits: BIT_VECTOR) return integer;
  function to_sint(bits: ieee.std_logic_1164.STD_LOGIC_VECTOR) return integer;
  function To_BitVector32(number : integer) return BIT_VECTOR;
  function to_word(number : integer) return ieee.std_logic_1164.STD_LOGIC_VECTOR;
end UTILS;


package body UTILS is

  function to_uint(bits: BIT_VECTOR) return integer is
  begin
    return to_integer(unsigned(bits));
  end to_uint;
  
  function to_uint(bits: ieee.std_logic_1164.STD_LOGIC_VECTOR) return integer is
  begin
    return IEEE.STD_LOGIC_ARITH.conv_integer(IEEE.STD_LOGIC_ARITH.unsigned(bits));
  end to_uint;
  
  function to_sint(bits: BIT_VECTOR) return integer is
  begin
    return to_integer(signed(bits));
  end to_sint;
  
  function to_sint(bits: ieee.std_logic_1164.STD_LOGIC_VECTOR) return integer is
  begin
    return IEEE.STD_LOGIC_ARITH.conv_integer(IEEE.STD_LOGIC_ARITH.signed(bits));
  end to_sint;
  
  function To_BitVector32(number : integer) return BIT_VECTOR is
  begin
    return BIT_VECTOR(to_unsigned(number,32));
  end To_BitVector32;
  
  -- need signed or unsigned conversion ??
  --
  function to_word(number : integer) return ieee.std_logic_1164.STD_LOGIC_VECTOR is
  begin
    return ieee.std_logic_1164.STD_LOGIC_VECTOR(ieee.numeric_std.to_signed(number,32));
  end to_word;
   
end UTILS;


LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

package DE2_115 is
  subtype GREEN_LEDS is BIT_VECTOR (7 downto 0);
  subtype RED_LEDS   is BIT_VECTOR (17 downto 0);
  subtype SWITCHES   is BIT_VECTOR (17 downto 0);
  
  subtype DIGIT_CODE is STD_LOGIC_VECTOR(0 to 6);
  
  function GetDigitCode(digit : in integer range 0 to 15) return DIGIT_CODE;
  
end DE2_115;

package body DE2_115 is
  
  function GetDigitCode(digit : in integer range 0 to 15) return DIGIT_CODE is
  begin
    
    case digit is 
      when 0 => return not "1111110";
      when 1 => return not "0110000";
      when 2 => return not "1101101";
      when 3 => return not "1111001";
      
      when 4 => return not "0110011";
      when 5 => return not "1011011";
      when 6 => return not "1011111";
      when 7 => return not "1110000";
      
      when 8 => return not "1111111";
      when 9 => return not "1111011";
      when 10 => return not "1110111";
      when 11 => return not "0011111";
      
      when 12 => return not "1001110";
      when 13 => return not "0111101";
      when 14 => return not "1001111";
      when 15 => return not "1000111";
           
      when others => return not "0000000";
    end case;
  
  end GetDigitCode;
 
  
  
end DE2_115;


LIBRARY work;
LIBRARY ieee;
USE work.DE2_115.all;
USE ieee.std_logic_1164.all;
USE ieee.STD_LOGIC_ARITH.all;
use IEEE.numeric_std.all;
USE work.UTILS.all;

entity Number_Display is
  PORT(	
    number : in integer;
    HEX_0 : out DIGIT_CODE;
    HEX_1 : out DIGIT_CODE;
    HEX_2 : out DIGIT_CODE;
    HEX_3 : out DIGIT_CODE;
    HEX_4 : out DIGIT_CODE;
    HEX_5 : out DIGIT_CODE;
    HEX_6 : out DIGIT_CODE;
    HEX_7 : out DIGIT_CODE
  );
END Number_Display;

-- 
--
architecture RTL of Number_Display is

begin
  
  p0 : process(number)
    variable num_b : BIT_VECTOR (31 downto 0);
    variable H0,H1,H2,H3,H4,H5,H6,H7: BIT_VECTOR (3 downto 0);
  begin
  
    num_b := To_BitVector32(number);
    
    H0 := num_b(3 downto 0);
    H1 := num_b(7 downto 4);
    H2 := num_b(11 downto 8);
    H3 := num_b(15 downto 12);
    H4 := num_b(19 downto 16);
    H5 := num_b(23 downto 20);
    H6 := num_b(27 downto 24);
    H7 := num_b(31 downto 28);
    
    HEX_0 <= GetDigitCode(to_uint(H0));
    HEX_1 <= GetDigitCode(to_uint(H1));
    HEX_2 <= GetDigitCode(to_uint(H2));
    HEX_3 <= GetDigitCode(to_uint(H3));
    HEX_4 <= GetDigitCode(to_uint(H4));
    HEX_5 <= GetDigitCode(to_uint(H5));
    HEX_6 <= GetDigitCode(to_uint(H6));
    HEX_7 <= GetDigitCode(to_uint(H7));
    
  end process;
  
end RTL;


