LIBRARY ieee;
LIBRARY work;
USE ieee.std_logic_1164.all;
USE work.UTILS.all;


package A0 is
  
  subtype WORD is STD_LOGIC_VECTOR (31 downto 0);
  subtype BYTE is STD_LOGIC_VECTOR (7 downto 0);
  
  subtype REGT is integer range 0 to 15;
  
  type PROGRAM_MEMORY   is array (0 to 16384) of WORD; 
  type L1_MEMORY        is array (0 to 65535) of WORD; 
  type REGISTER_MEMORY  is array (0 to 15)    of WORD; 
 
  constant A_NOP   : STD_LOGIC_VECTOR(3 downto 0) := "0000";
  constant A_MOV   : STD_LOGIC_VECTOR(3 downto 0) := "0001";
  constant A_ADD   : STD_LOGIC_VECTOR(3 downto 0) := "0010";
  constant A_SUB   : STD_LOGIC_VECTOR(3 downto 0) := "0011";
  constant A_ADC   : STD_LOGIC_VECTOR(3 downto 0) := "0100";
  constant A_CMP   : STD_LOGIC_VECTOR(3 downto 0) := "0101";
  constant A_AND   : STD_LOGIC_VECTOR(3 downto 0) := "0110";
  constant A_OR    : STD_LOGIC_VECTOR(3 downto 0) := "0111";
  constant A_NOT   : STD_LOGIC_VECTOR(3 downto 0) := "1000";
  constant A_XOR   : STD_LOGIC_VECTOR(3 downto 0) := "1001";
  constant A_SHL   : STD_LOGIC_VECTOR(3 downto 0) := "1010";
  constant A_SHR   : STD_LOGIC_VECTOR(3 downto 0) := "1011";
  constant A_MUL   : STD_LOGIC_VECTOR(3 downto 0) := "1100";
  constant A_NN1   : STD_LOGIC_VECTOR(3 downto 0) := "1110";
  constant A_NN2   : STD_LOGIC_VECTOR(3 downto 0) := "1111";
					  
  constant M_NOP   : STD_LOGIC_VECTOR(1 downto 0) := "00";
  constant M_LOAD  : STD_LOGIC_VECTOR(1 downto 0) := "01";
  constant M_STORE : STD_LOGIC_VECTOR(1 downto 0) := "10";
  constant M_SWAP  : STD_LOGIC_VECTOR(1 downto 0) := "11";
  
  constant C_NOP   : STD_LOGIC_VECTOR(1 downto 0) := "00";
  constant C_JMP   : STD_LOGIC_VECTOR(1 downto 0) := "01";
  constant C_HLT   : STD_LOGIC_VECTOR(1 downto 0) := "10";
  constant C_INT   : STD_LOGIC_VECTOR(1 downto 0) := "11";
  						
  
  type Flags is record		 
	N  : STD_LOGIC; -- apply not to the rest of flags
    Z  : STD_LOGIC; -- Zero
    LT : STD_LOGIC; -- Less Than
    LE : STD_LOGIC; -- Less Equal
  end record;				  
  
  
  -- unlike common implementation, there is no immediate bit fields in instruction
  -- Immediate data will be taken as whole next instruction word. Like this:
  --
  -- "add R0, R1, 65536" --> 
  --  add R0, R1, 0 
  --  65536	  
  -- ----------------------> so, I-type instructions take 2 clock cycles in simple implementation
  
  constant INSTR_ALUI : STD_LOGIC_VECTOR(1 downto 0) := "00";
  constant INSTR_MEM  : STD_LOGIC_VECTOR(1 downto 0) := "10"; 
  constant INSTR_CNTR : STD_LOGIC_VECTOR(1 downto 0) := "01";
  constant INSTR_ALUF : STD_LOGIC_VECTOR(1 downto 0) := "11";
  
  -- ALUI: 
  --
  -- F     F    F  F  F  FF  F
  -- 01 00 CODE R0 R1 R2 00  FLAGS	  R-type instruction; r, 1, a, add, R0, R1, R2  
  -- 11 00 CODE R0 R1 0  00  FLAGS	  I-type instruction; i, 1, a, add, R0, R1, 
  --                                                      d, {-655362345}   
 
  -- MEM: 
  --
  -- F       F    F F  F  FF     F
  -- 00 10 0 CODE 0 R1 [R2+OFFS] FLAGS  R-type instruction; r, 0, m, sw, 0, R1, R2, 255 // mem(R2+255) := R1;
  -- 10 10 0 CODE 0 R1 [R2+OFFS] FLAGS  I-type instruction; i, 0, m, sw, 0, R1, R2, 255 // mem(R2+255) := -655362345; 
  --                                                        d, {-655362345}		        //				    
  --                                                        r, 1, m, lw R0, 0, R2, 255  // R0 := mem(R2+255);
                                                       
  -- CONTROL:	 
  -- F     F    F F  F  FF    F																						   
  -- 00 01 CODE 0 R1 0  00    FLAGS  R-type instruction; r, 0, c, jmp, 0, 0, R2 // jmp [R2]
  -- 10 01 CODE 0 0  0  00    FLAGS  I-type instruction; i, 0, c, jmp    	    // jmp [ADDRESS]
  --                                                        d, {ADDRESS}
 
  -- FLOAT:
  -- 01 11 ... same as for ALUI.
  
  -- OPCODE = "00" & CODE where "00" is instruction type
  
  --
  type Instruction is record
	imm     : boolean;										  
	we      : boolean;                     -- write enable
	itype   : STD_LOGIC_VECTOR (1 downto 0); -- instruction type  
    code    : STD_LOGIC_VECTOR (3 downto 0);	
    reg0    : REGT;
    reg1    : REGT;
    reg2    : REGT;	  
	memOffs : STD_LOGIC_VECTOR(7 downto 0);  -- used only by memory instructions
	flags   : Flags; 
	invalid : boolean; 
  end record;			   
  
  constant CMD_NOP : Instruction := (imm => false, we=>false, code => "0000", itype=> "00", reg0 => 0, reg1 => 0, reg2 => 0, memOffs => x"00", flags => (others => '0'), invalid => false);
  
  function ToInstruction(data : WORD) return Instruction; 
  function ToStdLogic(L: BOOLEAN) return std_logic;	
  function ToBoolean(L: std_logic) return BOOLEAN;
  
end A0;


package body A0 is

  
  function ToInstruction(data : WORD) return Instruction is
    variable cmd : Instruction;
  begin	
	cmd.imm      := ToBoolean(data(31));						          -- first bit is 'immediate' flag	
	cmd.we       := ToBoolean(data(30));								  -- second is 'write back' flag
	cmd.itype	 := data(29 downto 28);						  -- next 2-bit instruction type
	cmd.code     := data(27 downto 24);				          -- next 4 bit for opcodes	
	cmd.reg0     := to_uint(data(23 downto 20));			  -- next 4 bits for reg0
	cmd.reg1     := to_uint(data(19 downto 16));			  -- next 4 bits for reg1
	cmd.reg2     := to_uint(data(15 downto 12));			  -- next 4 bits for reg2
    cmd.memOffs	 :=         data(11 downto 4);
    cmd.invalid  := false;	
	cmd.flags.N  := data(3);								  -- last 4 bits for flags
	cmd.flags.Z  := data(2);
	cmd.flags.LE := data(1);
	cmd.flags.LT := data(0);  
    return cmd;
  end ToInstruction;

  function ToStdLogic(L: BOOLEAN) return std_logic is
  begin
    if L then
      return('1');
     else
      return('0');
    end if;
  end ToStdLogic; 	 
  
  
  function ToBoolean(L: std_logic) return BOOLEAN is
  begin
    if L = '1' then
      return true;
     else
      return false;
    end if;
  end ToBoolean; 	 
  
end A0;


-----------------------------------------------------------------------------------------
--------------------------- main entity -----------------------------------------------
-----------------------------------------------------------------------------------------

LIBRARY ieee;
LIBRARY work;
USE ieee.std_logic_1164.all;
USE work.DE2_115.all;
USE work.UTILS.all;
USE work.A0.all;


ENTITY A1_CPU IS
	PORT(	  
	  CLOCK_50 : in STD_LOGIC;	
	  RESET_50 : in	STD_LOGIC
		);
END A1_CPU;

ARCHITECTURE RTL OF A1_CPU IS 

  --alias clk : STD_LOGIC is CLOCK_50;	  
  --alias rst : STD_LOGIC is RESET_50;
  
  signal clk  : STD_LOGIC := '0';  
  signal rst  : STD_LOGIC := '0';
  
  signal ip   : integer range 0 to 16384 := 0;	-- instruction pointer
  
  signal cmdD : Instruction := CMD_NOP; 
  signal cmdX : Instruction := CMD_NOP; 
  signal cmdM : Instruction := CMD_NOP;
  signal cmdW : Instruction := CMD_NOP;
 
  signal program  : PROGRAM_MEMORY  := 
  ( 
   0 => x"C1100000",
   1 => x"00000003",
   2 => x"C1200000",
   3 => x"00000002",
   4 => x"42012000",
   5 => x"12000000",
   6 => x"12000000",
   7 => x"12000000",
   others => x"00000000"
   );  
  
  
  signal memory   : L1_MEMORY       := (others => x"00000000");  -- in real implementation this should be out of chip
  signal regs     : REGISTER_MEMORY := (others => x"00000000");
  
  --signal mem_offs : std_logic_vector(7 downto 0); 
  
  signal op1_inputX  : WORD := x"00000000";
  signal op2_inputX  : WORD := x"00000000"; 
  
  signal op1_inputM  : WORD := x"00000000";
  signal op2_inputM  : WORD := x"00000000";
  
  signal resultX     : WORD := x"00000000"; -- after ALU 
  signal resultM     : WORD := x"00000000"; -- after MEM	
  
  signal flags     : Flags;
  
BEGIN	
  
  -- this is for simulation purposes only 
  --
  clock : process
  begin
	
   rst <= '1'; 
   wait for 10 ns;	 
   
   rst <= '0';
   wait for 10 ns;
   
   while true loop	   
     wait for 10 ns; 
     clk  <= not clk;
   end loop;
   
  end process clock;
  
  
  main : process(clk,rst)
  
    -------------- fetch input ----------------
    variable cmdF    : Instruction;
  	variable rawCmdF : WORD;  				   
	variable stall   : boolean := false;
	-------------- fetch input ----------------	
	
	-------------- mem input ----------------
	variable address : integer range 0 to 255 := 0;
	variable memIn   : WORD := x"00000000";    
	-------------- mem input ----------------
	
	-------------- alu input ----------------
	variable xA : WORD := x"00000000"; 
	variable xB : WORD := x"00000000";	
	
	variable iA : integer := 0;
    variable iB : integer := 0;
	-------------- alu input ----------------
	
  begin						

   if (rst = '1') then

     ip    <= 0;
	 cmdD  <= CMD_NOP;
	   
   elsif rising_edge(clk) then	   
	
     -----------------------------------------------------------------------------------------------------------------
	 ---------------------------------------  core arch begin --------------------------------------------------------
	 -----------------------------------------------------------------------------------------------------------------	 
	
	 ---- instruction fetch and pipeline basics ----
	 
	 rawCmdF := program(ip);
	 cmdF    := ToInstruction(rawCmdF);
	 
	 -- this is the only case for 5-stage RISC processor when we must stall 
     --
	 stall   := (cmdF.itype = INSTR_ALUI) and (cmdD.itype = INSTR_MEM) and cmdD.we and (cmdD.reg0 = cmdF.reg1 or cmdD.reg0 = cmdF.reg2); 
	 
	 if stall or cmdD.imm then -- push nop to cmdD in next cycle, cause if cmdD is immediate, next instructions is it's data
	   cmdD <= CMD_NOP;
	 else
	   cmdD <= cmdF;
	 end if;
	 
	 -- 0 1 2 3 4
	 -- F D X M W
	 --
	 cmdX <= cmdD; -- from D to X
	 cmdM <= cmdX; -- from X to M
	 cmdW <= cmdM; -- from M to W
	 
	 ---- instruction fetch and pipeline basics ----   
	 
	 
	 ---- register fetch ----
	
	 op1_inputX <= regs(cmdD.reg1);
	
	 if cmdD.imm then		   
	   op2_inputX <= rawCmdF;
	 else  
	   op2_inputX <= regs(cmdD.reg2); -- to_word(cmdF)
     end if;
	  
	 op1_inputM <= op1_inputX;
	 op2_inputM <= op2_inputX;
	 
	 ---- register fetch ----
	 
	 
	 ---- control unit ----
	 if stall then
	   ip <= ip;
	 else
	   ip <= ip+1;
	 end if;	  
     ---- control unit ----	
	 
	 
	 ---- execution stage ----
	 
	 if cmdX.itype = INSTR_ALUI then 				
		
	   -------------------------- bypassing ----------------------------	 
	   if    cmdM.reg0 = cmdX.reg1 and cmdM.we then   -- bypass result from X to op1
	     xA := resultX;
       elsif cmdW.reg0 = cmdX.reg1 and cmdW.we then   -- bypass result from M to op1
		 xA := resultM; 
	   else	
	     xA := op1_inputX;
	   end if;
		 
	   if    cmdM.reg0 = cmdX.reg2 and cmdM.we then   -- bypass result from X to op2
	     xB := resultX;
       elsif cmdW.reg0 = cmdX.reg2 and cmdW.we then   -- bypass result from M to op2
		 xB := resultM; 
	   else	
	     xB := op2_inputX;
	   end if;	  
	   -------------------------- bypassing ----------------------------
	   
	   -------------------------- alu core -----------------------------
	   iA := to_sint(xA);
       iB := to_sint(xB);
		 
	   case cmdX.code is	   
        when A_NOP =>   resultX <= x"00000000";
        when A_MOV =>   resultX <= xB;
        when A_ADD =>   resultX <= to_word(iA + iB); -- and write carry flag
        when A_SUB =>   resultX <= to_word(iA - iB); -- and write carry flag						 
             
        when A_CMP =>   flags.Z  <= '0'; -- (iA = iB); 
	                    flags.N  <= '0';
                        flags.LE <= ToStdLogic(iA <= iB); 
                        flags.LT <= ToStdLogic(iA <  iB);
					    resultX  <= x"00000000";
                          
        when A_AND =>   resultX <= xA and xB;
        when A_OR  =>   resultX <= xA  or xB;
        when A_NOT =>   resultX <= not xA;
        when A_XOR =>   resultX <= xA xor xB;
    
	    when A_SHL =>   resultX(31 downto 1) <= xB (30 downto 0);
                        resultX(0) <= '0';
                          
        when A_SHR  =>  resultX(31) <= '0';
                        resultX(30 downto 0) <= xB (31 downto 1);	  
						  
        --when A_ADC  =>   resultX <= to_word(iA + carry);	 	
        when A_MUL  =>   resultX <= to_word(iA * iB);  					  
        when others =>   resultX <= x"00000000"; report "Error, this command should not pass in to ALU";	   
      end case; 	 
	  -------------------------- alu core ----------------------------- 

	  
	 else
	   resultX <= x"00000000";	 
     end if;
	 
	 ---- execution stage ----
	 
	 
	 ---- memory stage ----
	
	 if cmdM.itype = INSTR_MEM then 		
		 
       if cmdW.reg0 = cmdM.reg2 and cmdW.we then -- bypass result from M to address
	     address := to_uint(resultM)  + to_uint(cmdM.memOffs);
       else	
	     address := to_uint(op2_inputM) + to_uint(cmdM.memOffs);
	   end if;
		 
	   if cmdW.reg0 = cmdM.reg1 and cmdW.we then -- bypass result from M to data
		 memIn := resultM;
	   else
	     memIn := op1_inputM; 
	   end if;
	   
	   case cmdM.code(1 downto 0) is
	     when M_LOAD  =>   resultM         <= memory(address);   
	     when M_STORE =>   memory(address) <= memIn; 
		   				   resultM         <= x"00000000";
         when others  =>   resultM         <= x"00000000"; 
       end case;
	  
	 else
	   resultM <= resultX;	 
     end if;
	 
	 ---- memory stage ----
	 
	 
	 ---- write back   ----	  
	 if cmdW.we and not cmdW.invalid then
	   regs(cmdW.reg0) <= resultM;
	 end if;
	 ---- write back   ----
	 
	 -----------------------------------------------------------------------------------------------------------------
	 ---------------------------------------- core arch end ----------------------------------------------------------
	 -----------------------------------------------------------------------------------------------------------------
   
    end if;
   
  end process main;
 
   
END RTL;

