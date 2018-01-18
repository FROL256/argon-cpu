LIBRARY ieee;
LIBRARY work;
USE ieee.std_logic_1164.all; 
USE ieee.numeric_std.all;
USE work.UTILS.all;

package A0 is
  
  subtype WORD is STD_LOGIC_VECTOR (31 downto 0);
  subtype BYTE is STD_LOGIC_VECTOR (7 downto 0);
  
  subtype REGT is integer range 0 to 15;
  
  type PROGRAM_MEMORY   is array (0 to 255)  of WORD; 
  type L1_MEMORY        is array (0 to 1023) of WORD; 
  type REGISTER_MEMORY  is array (0 to 15)   of WORD; 
  
  type testtype is array (1 to 27) of string(1 to 24);
 
  constant A_NOP   : STD_LOGIC_VECTOR(3 downto 0) := "0000";   
  constant A_SHL   : STD_LOGIC_VECTOR(3 downto 0) := "0001";  -- SLA is encoded as signed SHL
  constant A_SHR   : STD_LOGIC_VECTOR(3 downto 0) := "0010";  -- SRA is encoded as signed SHR
  constant A_MOV   : STD_LOGIC_VECTOR(3 downto 0) := "0011";
  
  constant A_ADD   : STD_LOGIC_VECTOR(3 downto 0) := "0100";
  constant A_ADC   : STD_LOGIC_VECTOR(3 downto 0) := "0101"; -- x + y + carry
  constant A_SUB   : STD_LOGIC_VECTOR(3 downto 0) := "0110"; 
  constant A_SBC   : STD_LOGIC_VECTOR(3 downto 0) := "0111"; -- x - y - carry
  
  constant A_AND   : STD_LOGIC_VECTOR(3 downto 0) := "1000";
  constant A_OR    : STD_LOGIC_VECTOR(3 downto 0) := "1001";
  constant A_NOT   : STD_LOGIC_VECTOR(3 downto 0) := "1010";
  constant A_XOR   : STD_LOGIC_VECTOR(3 downto 0) := "1011";
  
  constant A_MFH   : STD_LOGIC_VECTOR(3 downto 0) := "1100"; -- Move From High
  constant A_MUL   : STD_LOGIC_VECTOR(3 downto 0) := "1111";
  --constant A_NN2   : STD_LOGIC_VECTOR(3 downto 0) := "1101";
  --constant A_NN3   : STD_LOGIC_VECTOR(3 downto 0) := "1110";
            
  constant M_NOP   : STD_LOGIC_VECTOR(1 downto 0) := "00";
  constant M_LOAD  : STD_LOGIC_VECTOR(1 downto 0) := "01";
  constant M_STORE : STD_LOGIC_VECTOR(1 downto 0) := "10";
  constant M_SWAP  : STD_LOGIC_VECTOR(1 downto 0) := "11";
  
  constant C_NOP   : STD_LOGIC_VECTOR(2 downto 0) := "000";
  constant C_JMP   : STD_LOGIC_VECTOR(2 downto 0) := "001";
  constant C_JRA   : STD_LOGIC_VECTOR(2 downto 0) := "100";
  constant C_HLT   : STD_LOGIC_VECTOR(2 downto 0) := "010";
  constant C_INT   : STD_LOGIC_VECTOR(2 downto 0) := "011";
              
  type Flags is record     
    N  : boolean; -- if set, invert flags (Z,LT,P)
    Z  : boolean; -- Zero
    LT : boolean; -- Less Than
    P  : boolean; -- Predicate  
    CF : boolean; -- if command set flags
    S  : boolean; -- if operation is signed
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
  -- 01 00 CODE R0 R1 R2 00  FLAGS    R-type instruction; r, 1, a, add, R0, R1, R2  
  -- 11 00 CODE R0 R1 0  00  FLAGS    I-type instruction; i, 1, a, add, R0, R1, 
  --                                                      d, {-655362345}   
 
  -- MEM: 
  --
  -- F       F    F F  F  FF     F
  -- 00 10 0 CODE 0 R1 [R2+OFFS] FLAGS  R-type instruction; r, 0, m, sw, 0, R1, R2, 255 // mem(R2+255) := R1;
  -- 10 10 0 CODE 0 R1 [R2+OFFS] FLAGS  I-type instruction; i, 0, m, sw, 0, R1, R2, 255 // mem(R2+255) := -655362345; 
  --                                                        d, {-655362345}           //            
  --                                                        r, 1, m, lw R0, 0, R2, 255  // R0 := mem(R2+255);
                                                       
  -- CONTROL:  
  -- F     F    F F  F  FF    F                                              
  -- 00 01 CODE 0 R1 0  00    FLAGS  R-type instruction; r, 0, c, jmp, 0, 0, R2 // jmp [R2]
  -- 10 01 CODE 0 0  0  00    FLAGS  I-type instruction; i, 0, c, jmp         // jmp [ADDRESS]
  --                                                        d, {ADDRESS}
 
  -- FLOAT:
  -- 01 11 ... same as for ALUI.
  
  -- OPCODE = "00" & CODE where "00" is instruction type
  --
  type Instruction is record
    imm     : boolean;                       -- immediate flag          
    we      : boolean;                       -- write enable
    itype   : STD_LOGIC_VECTOR (1 downto 0); -- instruction type  
    code    : STD_LOGIC_VECTOR (3 downto 0); -- instruction op-code 
    reg0    : REGT;
    reg1    : REGT;
    reg2    : REGT;   
    memOffs : STD_LOGIC_VECTOR(7 downto 0);  -- used only by memory instructions 
    flags   : Flags;                         -- predicates
    invalid : boolean;                       -- used later if instruction marked invalid due to predicates or cache miss
    op1     : WORD;
    op2     : WORD;
    res     : WORD;
  end record;        
  
  constant CMD_NOP : Instruction := (imm => false, we=>false, code => "0000", itype=> "00", reg0 => 0, reg1 => 0, reg2 => 0, 
                                     memOffs => x"00", flags => (others => false), invalid => false,
                                     op1 => x"00000000", op2 => x"00000000", res => x"00000000");
  
  function ToInstruction(data : WORD) return Instruction; 
  function ToStdLogic(L: BOOLEAN) return std_logic; 
  function ToBoolean(L: std_logic) return BOOLEAN; 
  function InvalidateCmdIfFlagsDifferent(cmdxflags : Flags; flags_Z : boolean; flags_LT : boolean; flags_P : boolean) return boolean;
  
  procedure ALUIntOperation(cmdX : Instruction; xA : WORD; xB : WORD; 
                            signal carryOut : inout std_logic;
                            signal flags_Z  : inout boolean; 
                            signal flags_LT : inout boolean;
                            signal resLow   : inout WORD;
                            signal resHigh  : inout WORD;
                            signal addOut   : out WORD);

end A0;

package body A0 is
  
  function ToInstruction(data : WORD) return Instruction is
    variable cmd : Instruction;
  begin 
    
    cmd.imm      := ToBoolean(data(31));          -- first bit is 'immediate' flag  
    cmd.we       := ToBoolean(data(30));          -- second is 'write enable' flag
    cmd.itype    :=         data(29 downto 28);   -- next 2-bit instruction type
    cmd.code     :=         data(27 downto 24);   -- next 4 bit for opcodes 
    cmd.reg0     := to_uint(data(23 downto 20));  -- next 4 bits for reg0
    cmd.reg1     := to_uint(data(19 downto 16));  -- next 4 bits for reg1
    cmd.reg2     := to_uint(data(15 downto 12));  -- next 4 bits for reg2 
    cmd.memOffs  :=         data(11 downto 4);
    
    if cmd.itype = INSTR_ALUI then                -- don't use memOffs, read flags instead
      cmd.flags.S  := ToBoolean(cmd.memOffs(7)); 
      cmd.flags.CF := ToBoolean(cmd.memOffs(6));
    end if;
    
    cmd.invalid  := false;  
    cmd.flags.N  := ToBoolean(data(3));           -- last 4 bits for flags
    cmd.flags.Z  := ToBoolean(data(2));
    cmd.flags.LT := ToBoolean(data(1));
    cmd.flags.P  := ToBoolean(data(0));
  
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
  
  
  function InvalidateCmdIfFlagsDifferent(cmdxflags : Flags; flags_Z : boolean; flags_LT : boolean; flags_P : boolean) return boolean is
  
    variable cmdFlagEQ : boolean := false; 
    variable cmdFlagLT : boolean := false;
    variable cmdFlagP  : boolean := false;
    variable valid     : boolean := false;
  
  begin    
    
    if cmdxflags.N then
      cmdFlagEQ := not cmdxflags.Z; 
      cmdFlagLT := not cmdxflags.LT; 
      cmdFlagP  := not cmdxflags.P;
    else
      cmdFlagEQ := cmdxflags.Z; 
      cmdFlagLT := cmdxflags.LT; 
      cmdFlagP  := cmdxflags.P;
    end if;
    
    if flags_Z then
      valid := cmdFlagEQ;
    else
      valid := (cmdFlagLT = flags_LT);  -- #TODO: don't use cmdFlagP, need to use it probably?
    end if;
    
    return not valid;
    
  end InvalidateCmdIfFlagsDifferent;
  
  -- do integer alu operation in a single cycle
  --
  procedure ALUIntOperation(cmdX : Instruction; xA : WORD; xB : WORD; 
                            signal carryOut : inout std_logic;
                            signal flags_Z  : inout boolean; 
                            signal flags_LT : inout boolean;
                            signal resLow   : inout WORD;
                            signal resHigh  : inout WORD;
                            signal addOut   : out WORD) is
   
  variable yB     : WORD                  := x"00000000";     -- second op passed to adder
  variable rShift : WORD                  := (others => '0'); -- result of shift ops group
  variable rLog   : WORD                  := (others => '0'); -- result of logic ops group
  variable rAdd   : unsigned(32 downto 0) := (others => '0'); -- result of add   ops group  
  variable rMulc  : WORD                  := (others => '0'); -- result of mult  ops group  
  variable rMul   : unsigned(63 downto 0) := (others => '0'); -- result of true multiplication  
  
  variable carryIn : std_logic := '0'; 
  variable zero    : std_logic := '0'; 
  
  variable shiftS   : std_logic := '0';   
  variable memInAlu : boolean   := false;   -- if current mem command in alu calc address    
  
  begin

  memInAlu := (cmdX.itype = INSTR_MEM);     
    
  if cmdX.code(1) = '1' and not memInAlu then  -- sub or sbc  
    yB := not xB;
  else   
    yB := xB;    
  end if;      
    
  carryIn := ToStdLogic( ((cmdX.code(1 downto 0) = "10") or (cmdX.code(1 downto 0) = "01" and carryOut = '1')) and not memInAlu); -- SUB or ADC and not mem operation
     
  rAdd := ("0" & unsigned(xA)) + unsigned(yB) + (unsigned'("") & carryIn); -- full 32 bit adder with carry
  carryOut <= rAdd(32);     
     
  zero := not (rAdd(31) or rAdd(30) or rAdd(29) or rAdd(28) or rAdd(27) or rAdd(26) or rAdd(25) or rAdd(24) or rAdd(23) or rAdd(22) or 
               rAdd(21) or rAdd(20) or rAdd(19) or rAdd(18) or rAdd(17) or rAdd(16) or rAdd(15) or rAdd(14) or rAdd(13) or rAdd(12) or 
               rAdd(11) or rAdd(10) or rAdd(9)  or rAdd(8)  or rAdd(7)  or rAdd(6)  or rAdd(5)  or rAdd(4)  or rAdd(3)  or rAdd(2)  or rAdd(1) or rAdd(0));
    
  if cmdX.itype = INSTR_ALUI then
   
    if cmdX.flags.CF then
      flags_Z  <= (zero     = '1');
      flags_LT <= (rAdd(31) = '1');  -- sign bit
    else
      flags_Z   <= flags_Z;
      flags_LT <= flags_LT;
    end if;
    
   ----------------------------------------------------------------- mul group  (may be need to optimize, may be not)
     
   if cmdX.flags.S then 
     rMul := unsigned(signed(xA) * signed(xB));
   else
     rMul := unsigned(xA) * unsigned(xB);         -- full 32 to 64 bit signed/unsigned multiplyer;  
   end if;
    
   resHigh <= std_logic_vector(rMul(63 downto 32)); -- always write this reg, so we must get the hight reg in next command immediately or loose it
    
   case cmdX.code(1 downto 0) is
     when "11"   => rMulc := std_logic_vector(rMul(31 downto 0)); -- constant A_MUL : STD_LOGIC_VECTOR(3 downto 0) := "1111"; 
     when others => rMulc := resHigh;                 -- constant A_MFH : STD_LOGIC_VECTOR(3 downto 0) := "1100"; -- Move From High
   end case;
    
   ----------------------------------------------------------------- logic group
   --
   case cmdX.code(1 downto 0) is
     when "00"   => rLog := xA and xB;   
     when "01"   => rLog := xA or  xB;
     when "10"   => rLog :=    not xA;
     when others => rLog := xA xor xB;
   end case;  
    
   ----------------------------------------------------------------- shift group
   -- 
   if cmdX.flags.S then  
     shiftS := xA(31);   -- arithmetic shifts
   else
     shiftS := '0';      -- common shifts
   end if;
    
   case cmdX.code(1 downto 0) is
     when "01"   => rShift := xA(30 downto 0) & '0';     -- replace with sll
                    if cmdX.flags.S then 
                      rShift(31) := shiftS;
                    end if;  
     when "10"   => rShift := shiftS & xA(31 downto 1);  -- replace with srl
     when "11"   => rShift := xB;
     when others => rShift := x"00000000";
   end case;
    
   -- get final result   
   --
   case cmdX.code(3 downto 2) is     
       when "00"   => resLow  <= rShift;
       when "01"   => resLow  <= std_logic_vector(rAdd(31 downto 0));
       when "10"   => resLow  <= rLog;
       when others => resLow  <= rMulc;
   end case;   
   -------------------------- alu core ----------------------------- 
  else
    resLow <= x"00000000";
  end if;
 
  addOut <= std_logic_vector(rAdd(31 downto 0));
     
  end ALUIntOperation; 

  
end A0;


-----------------------------------------------------------------------------------------
--------------------------- main entity -----------------------------------------------
-----------------------------------------------------------------------------------------

LIBRARY ieee;
LIBRARY work;

USE ieee.std_logic_1164.all; 
USE ieee.numeric_std.all;

USE work.DE2_115.all;
USE work.UTILS.all;
USE work.A0.all;    
USE work.ATESTS.all;

use STD.textio.all;          -- for reading files
use ieee.std_logic_textio.all;     -- for reading files

ENTITY A1_CPU IS
  PORT(   
    CLOCK_50 : in STD_LOGIC;  
    RESET_50 : in STD_LOGIC
    );
END A1_CPU;

ARCHITECTURE RTL OF A1_CPU IS 

  --alias clk : STD_LOGIC is CLOCK_50;    
  --alias rst : STD_LOGIC is RESET_50;
  
  signal clk  : STD_LOGIC := '0';  
  signal rst  : STD_LOGIC := '0';
  
  signal ip   : integer range 0 to PROGRAM_MEMORY'high := 0;  -- instruction pointer
  
  signal afterF : Instruction := CMD_NOP; 
  signal afterD : Instruction := CMD_NOP; 
  signal afterX : Instruction := CMD_NOP;
  signal afterM : Instruction := CMD_NOP;
  
  signal program  : PROGRAM_MEMORY  := (others => x"00000000"); -- in real implementation this should be out of chip
  signal memory   : L1_MEMORY       := (others => x"00000000"); -- in real implementation this should be out of chip
  signal regs     : REGISTER_MEMORY := (others => x"00000000");
  
  signal imm_value   : WORD := x"00000000";
 
  
  signal flags_Z  : boolean := false; -- Zero
  signal flags_LT : boolean := false; -- Less Than
  signal flags_P  : boolean := false; -- Custom Predicate 
  
  signal carryOut  : std_logic := '0';  
  signal highValue : WORD := x"00000000";   
  
  signal halt : boolean := false; 
  
BEGIN 
  
  ------------------------------------ this process is only for simulation purposes ------------------------------------
  clock : process   
  
  file     file_PROG : text; -- file there the program is located 
  variable v_ILINE   : line;  
  variable v_CMD     : WORD; 
  variable i         : integer := 0; 
  variable testId    : integer := 0;  
  
  constant binFiles : testtype := (1  => "../../ASM/bin/out001.txt", 
                                   2  => "../../ASM/bin/out002.txt",
                                   3  => "../../ASM/bin/out003.txt",
                                   4  => "../../ASM/bin/out004.txt", 
                                   5  => "../../ASM/bin/out005.txt",
                                   6  => "../../ASM/bin/out006.txt",
                                   7  => "../../ASM/bin/out007.txt",
                                   8  => "../../ASM/bin/out008.txt",
                                   9  => "../../ASM/bin/out009.txt",
                                   10 => "../../ASM/bin/out010.txt",
                                   11 => "../../ASM/bin/out011.txt",
                                   12 => "../../ASM/bin/out012.txt",
                                   13 => "../../ASM/bin/out013.txt",
                                   14 => "../../ASM/bin/out014.txt",
                                   15 => "../../ASM/bin/out015.txt",
                                   16 => "../../ASM/bin/out016.txt",
                                   17 => "../../ASM/bin/out017.txt",
                                   18 => "../../ASM/bin/out018.txt",
                                   19 => "../../ASM/bin/out019.txt",
                                   20 => "../../ASM/bin/out020.txt",
                                   21 => "../../ASM/bin/out021.txt",
                                   22 => "../../ASM/bin/out022.txt",
                                   23 => "../../ASM/bin/out023.txt",
                                   24 => "../../ASM/bin/out024.txt",
                                   25 => "../../ASM/bin/out025.txt",
                                   26 => "../../ASM/bin/out026.txt",
                                   27 => "../../ASM/bin/out027.txt"
                                  );
  
  begin     
    
  for testId in binFiles'low to binFiles'high loop
      
   clk <= '0';
   rst <= '0';
   
   ------------------------------------ read program from file -------------------------------------------------
   file_open(file_PROG, binFiles(testId), read_mode); 
     
   i := 0;
   while not endfile(file_PROG) loop   
     readline(file_PROG, v_ILINE); 
     read(v_ILINE, v_CMD);
     program(i) <= v_CMD;
     i := i+1;    
   end loop;
   
   file_close(file_PROG);
   ------------------------------------ reset and begin to work -------------------------------------------------  
   
   rst <= '1'; 
   wait for 10 ns;   
   
   rst <= '0';
   wait for 10 ns;
   
   i := 0;
   while i < 1000 loop     
     wait for 10 ns; 
     clk  <= not clk;
     i := i+1;
   end loop;   

   ------------------------------------ finish                  ------------------------------------------------- 
   
   if CheckTest(testId, to_sint(regs(0)), to_sint(regs(1)), to_sint(regs(2))) then
     report "TEST " & integer'image(testId) & " PASSED!";
   else
     report "TEST " & integer'image(testId) & " FAILED! " & ": R0 = " & integer'image(to_sint(regs(0))) & ", R1 = " & integer'image(to_sint(regs(1))) & ", R2 = " & integer'image(to_sint(regs(2))); 
   end if;
   
   end loop; 
   
   report "end of simulation" severity failure;
   
  end process clock;
  ------------------------------------ this is only for simulation purposes ------------------------------------
    
  main : process(clk,rst)
  
  -------------- fetch input ----------------
  variable cmdF    : Instruction;
  variable rawCmdF : WORD;             
  variable bubble  : boolean := false;
  -------------- fetch input ---------------- 
  
  -------------- mem input ----------------
  variable address : integer := 0;  
  -------------- mem input ----------------
  
  -------------- alu input and internal ----------------
  variable xA : WORD := x"00000000"; -- first op
  variable xB : WORD := x"00000000"; -- second op 
    
  variable invalidateNow : boolean := false;
  variable haltNow : boolean := false;
  -------------- alu input and internal ----------------
  
  begin           

   if (rst = '1') then

     ip     <= 0;
     afterF <= CMD_NOP; 
     afterD <= CMD_NOP; 
     afterX <= CMD_NOP; 
     afterM <= CMD_NOP; 
     halt   <= false;
     
   elsif rising_edge(clk) then     
  
   -----------------------------------------------------------------------------------------------------------------
   ---------------------------------------  core arch begin --------------------------------------------------------
   -----------------------------------------------------------------------------------------------------------------   
  
   ------------------------------ instruction fetch and pipeline basics ------------------------------
   
   rawCmdF := program(ip);
   cmdF    := ToInstruction(rawCmdF);
   
   -- this is the only case for 5-stage RISC processor when we must bubble, because Mem operations have 2 clock latency
   -- load R0, [R1+2] --> F D X M W      | bypass after M to X
   -- add R3, R0, R1  -->   F F D X M W  |
   --
   haltNow := (cmdF.itype = INSTR_CNTR) and (cmdF.code(2 downto 0) = C_HLT);   
   bubble  := ((afterF.itype = INSTR_MEM) and afterF.we and (afterF.reg0 = cmdF.reg1 or afterF.reg0 = cmdF.reg2)) or haltNow;
   
   halt <= haltNow;

   if bubble or afterF.imm then -- push nop to afterF in next cycle, cause if afterF is immediate, next instructions is it's data
     afterF <= CMD_NOP;
   else
     afterF <= cmdF;
   end if;
   
   -- 0 1 2 3 4
   -- F D X M W
   --
   afterD <= afterF; 
   afterX <= afterD; -- here we have to deal with flags values and predicate commands
   
   invalidateNow := false;
   if afterD.flags.N or afterD.flags.Z or afterD.flags.LT or afterD.flags.P then       
     invalidateNow := InvalidateCmdIfFlagsDifferent(afterD.flags, flags_Z, flags_LT, flags_P);
     afterX.invalid <= invalidateNow;
     afterX.we      <= afterD.we and not invalidateNow; -- disable write to reg file if command is invalid
   end if;
   
   afterM <= afterX; -- from M to W
   
   ------------------------------ instruction fetch and pipeline basics ------------------------------   
   
   
   ------------------------------ register fetch ------------------------------
   
   if afterX.reg0 = afterF.reg1 and afterX.we then     -- bypass result from X to op1
     afterD.op1 <= afterX.res; 
   elsif afterM.reg0 = afterF.reg1 and afterM.we then  -- bypass result from M to op1
     afterD.op1 <= afterM.res; 
   else  
     afterD.op1 <= regs(afterF.reg1);                  -- ok, read from register file
   end if; 
   
   imm_value    <= rawCmdF;
   
   if afterF.imm then                                    -- read from instruction memory and ignore bypassing if commad is immediate
     afterD.op2 <= rawCmdF; 
   else       
     
     if afterX.reg0 = afterF.reg2 and afterX.we then     -- bypass result from X to op2
       afterD.op2 <= afterX.res; 
     elsif afterM.reg0 = afterF.reg2 and afterM.we then  -- bypass result from M to op1
       afterD.op2 <= afterM.res;
     else 
       afterD.op2 <= regs(afterF.reg2);                  -- ok, read from register file
     end if;    
     
   end if;
   
   ------------------------------ register fetch ------------------------------
   
   
   ------------------------------ execution stage ------------------------------
     
   
   ------------------------------ bypassing ------------------------------ 
   if    afterX.reg0 = afterD.reg1 and afterX.we then   -- bypass result from X to op1
     xA := afterX.res;
   elsif afterM.reg0 = afterD.reg1 and afterM.we then -- bypass result from M to op1
     xA := afterM.res; 
   else 
     xA := afterD.op1;
   end if;
     
   if    afterX.reg0 = afterD.reg2 and not afterD.imm and afterX.we then   -- bypass result from X to op2 and ignore bypassing second op for immediate commands
     xB := afterX.res;
   elsif afterM.reg0 = afterD.reg2 and not afterD.imm and afterM.we then   -- bypass result from M to op2 and ignore bypassing second op for immediate commands
     xB := afterM.res; 
   else 
     xB := afterD.op2;
   end if;    
   
   if (afterD.itype = INSTR_MEM) then  -- alter second op to compute address if mem istruction occured  
       
     if afterD.imm then 
       xA := imm_value;
     else
       xA := x"000000" & afterD.memOffs(7 downto 0);
     end if;
     
   end if;
   ------------------------------ bypassing ------------------------------
    
   ALUIntOperation(afterD, xA, xB, 
                   carryOut, flags_Z, flags_LT,
                   resLow  => afterX.res,
                   resHigh => highValue,
                   addOut  => afterX.op2);
  
   ------------------------------ control unit ------------------------------  
   if bubble then
     ip <= ip;
   elsif (afterD.itype = INSTR_CNTR and not invalidateNow) then

     if afterD.code(2 downto 0) = C_JMP  then
       ip <= to_uint(xB);          -- JMP, Jump Absolute Addr
     else
       ip <= to_uint(xB) + ip - 2; -- JRA, Jump Relative Addr
     end if;

   else
     ip <= ip+1;
   end if;    
   ------------------------------ control unit ------------------------------ 
   
   ------------------------------ memory stage ---- no bypassing from M to M
  
   if afterX.itype = INSTR_MEM and not afterX.invalid then    
     
     address := to_uint(afterX.op2);     
     
     case afterX.code(1 downto 0) is
       when M_LOAD  =>   afterM.res      <= memory(address);   
       
       when M_STORE =>   memory(address) <= afterX.op1;      
       
       when M_SWAP  =>   afterM.res      <= memory(address);   
                         memory(address) <= afterX.op1;
                   
       when others  =>   afterM.res      <= x"00000000"; 
     end case;
    
   else
     afterM.res <= afterX.res;   
   end if;
   
   ------------------------------ memory stage ------------------------------
   
   
   ------------------------------ write back ------------------------------   
   if afterM.we and not afterM.invalid then
     regs(afterM.reg0) <= afterM.res;  
   end if;
   ------------------------------ write back ------------------------------
   
   
   end if; -- end of rising_edge(clk)
   
  end process main;
 
   
END RTL;

