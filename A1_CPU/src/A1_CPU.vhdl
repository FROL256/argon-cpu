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
  type REGISTER_MEMORY  is array (0 to 15)   of WORD; 
  
  subtype INSTR_MEM_TYPE   is STD_LOGIC_VECTOR (1 downto 0);
  subtype ALU_MEM_TYPE     is STD_LOGIC_VECTOR (3 downto 0);
  subtype WHOLE_INSTR_CODE is STD_LOGIC_VECTOR (5 downto 0);
  
  -----------------------------------------------------------------------------------------------------------------------
  ---- scoreboard
  constant MAX_PIPE_LEN    : integer := 3;                                      -- allow max 3 stages of the pipeline, can be changed easily.
  subtype  PIPE_COUNT_T is integer range 0 to MAX_PIPE_LEN;                     -- per register counter type
 
  
  type SCOREBOARD_ELEM is record
    wbn  : STD_LOGIC;             -- write back now
    cmdt : INSTR_MEM_TYPE;        -- command type
  end record;
  
  type     SCOREBOARD_TYPE is array (0 to REGT'high)    of PIPE_COUNT_T;     -- array of per-register counters
  type     SCOREBOARD_FIFO is array (0 to MAX_PIPE_LEN) of SCOREBOARD_ELEM;  -- fifo to solve Write Back structural hazard and store command pipe id
  
  constant ALUI_PIPE_LEN : PIPE_COUNT_T := 1;
  constant MEM_PIPE_LEN  : PIPE_COUNT_T := 1;
  
  constant SCOREBOARD_ZERO_ELEM : SCOREBOARD_ELEM := (wbn => '0', cmdt => "00");
  constant SCOREBOARD_ZERO      : PIPE_COUNT_T := 0; 
  -----------------------------------------------------------------------------------------------------------------------
  
  type testtype is array (1 to 26) of string(1 to 24);
 
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
  --constant M_SWAP  : STD_LOGIC_VECTOR(1 downto 0) := "11";
  
  constant C_NOP   : STD_LOGIC_VECTOR(2 downto 0) := "000";
  constant C_JMP   : STD_LOGIC_VECTOR(2 downto 0) := "001";
  constant C_JRA   : STD_LOGIC_VECTOR(2 downto 0) := "100";
  constant C_HLT   : STD_LOGIC_VECTOR(2 downto 0) := "010";
  constant C_INT   : STD_LOGIC_VECTOR(2 downto 0) := "011";
 
  
  ------- #DEBUG: THIS IS FOR DEBUG NEEDS ONLY, TO SEE COMMAND NAME IN DEBUGGER ------ !!!
  
  type DEBUG_COMMAND is (DA_NOP, DA_SHL, DA_SHR, DA_MOV, 
                         DA_ADD, DA_ADC, DA_SUB, DA_SBC,
                         DA_AND, DA_OR,  DA_NOT, DA_XOR,
                         DA_MFH, DA_MUL, DA_NN1, DA_NN2,
                         DM_NOP, DM_LOAD, DM_STORE, 
                         DC_NOP, DC_JMP,  DC_JRA, DC_HLT, DC_INT);
                          
  function decodeDebug(code : in WHOLE_INSTR_CODE) return DEBUG_COMMAND;
  
  ------- #DEBUG: THIS IS FOR DEBUG NEEDS ONLY, TO SEE COMMAND NAME IN DEBUGGER ------ !!!
  
  
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
  
  constant INSTR_ALUI : INSTR_MEM_TYPE := "00";
  constant INSTR_MEM  : INSTR_MEM_TYPE := "10"; 
  constant INSTR_CNTR : INSTR_MEM_TYPE := "01";
  constant INSTR_ALUF : INSTR_MEM_TYPE := "11";
  
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
  --                                                        d, {-655362345}             //            
  --                                                        r, 1, m, lw R0, 0, R2, 255  // R0 := mem(R2+255);
                                                       
  -- CONTROL:  
  -- F     F    F F  F  FF    F                                              
  -- 00 01 CODE 0 R1 0  00    FLAGS  R-type instruction; r, 0, c, jmp, 0, 0, R2 // jmp [R2]
  -- 10 01 CODE 0 0  0  00    FLAGS  I-type instruction; i, 0, c, jmp           // jmp [ADDRESS]
  --                                                        d, {ADDRESS}
 
  -- FLOAT:
  -- 01 11 ... same as for ALUI.
  
  -- OPCODE = "00" & CODE where "00" is instruction type
  --
  type Instruction is record
    cmd     : DEBUG_COMMAND;                -- #DEBUG: THIS IS ONLY FOR DEBUG NEEDS!!!
    reg0    : REGT;
    reg1    : REGT;
    reg2    : REGT; 
    imm     : boolean;                      -- immediate flag          
    we      : boolean;                      -- write enable
    itype   : STD_LOGIC_VECTOR(1 downto 0); -- instruction type/pipe_id  
    code    : STD_LOGIC_VECTOR(3 downto 0); -- instruction op-code   
    memOffs : STD_LOGIC_VECTOR(7 downto 0); -- used only by memory instructions 
    flags   : Flags;                        -- predicates
    invalid : boolean;                      -- used later if instruction marked invalid due to predicates or cache miss
    op1     : WORD;
    op2     : WORD;
    res     : WORD;
  end record;        
  
  constant CMD_NOP : Instruction := (imm => false, we=>false, code => "0000", itype=> "00", reg0 => 0, reg1 => 0, reg2 => 0, 
                                     memOffs => x"00", flags => (others => false), invalid => false,
                                     op1 => x"00000000", op2 => x"00000000", res => x"00000000",
                                     cmd => DA_NOP);
  
  function ToInstruction(data : WORD) return Instruction; 
  function ToStdLogic(L: BOOLEAN) return std_logic; 
  function ToBoolean(L: std_logic) return BOOLEAN; 
  function InvalidateCmdIfFlagsDifferent(cmdxflags : Flags; flags_Z : boolean; flags_LT : boolean; flags_P : boolean) return boolean;
  
  function GetWriteEnableBit(cmd : Instruction) return boolean;
  
  function GetRes(afterX : Instruction; aluOut : WORD; memOut : WORD) return WORD;
  function GetOpA(afterD : Instruction; afterX : Instruction; xRes : WORD; imm_value : WORD) return WORD;
  function GetOpB(afterD : Instruction; afterX : Instruction; xRes : WORD) return WORD;
  
  function GetMemOp(cmdX : Instruction) return INSTR_MEM_TYPE;
  function GetAluOp(cmdX : Instruction) return ALU_MEM_TYPE;
                            
end A0;

package body A0 is
  
  ------- #DEBUG: THIS IS FOR DEBUG NEEDS ONLY, TO SEE COMMAND NAME IN DEBUGGER ------ !!!
  
  function decodeDebug(code : in WHOLE_INSTR_CODE) return DEBUG_COMMAND is 
  begin 
  case code is
    when "000000" => return DA_NOP; 
    when "000001" => return DA_SHL;   
    when "000010" => return DA_SHR;
    when "000011" => return DA_MOV;
    
    when "000100" => return DA_ADD;
    when "000101" => return DA_ADC;
    when "000110" => return DA_SUB;
    when "000111" => return DA_SBC;
    
    when "001000" => return DA_AND;
    when "001001" => return DA_OR;
    when "001010" => return DA_NOT;
    when "001011" => return DA_XOR;
    
    when "001100" => return DA_MFH;
    when "001111" => return DA_MUL;
    when "001101" => return DA_NN1;
    when "001110" => return DA_NN2;
    
    when "100000" => return DM_NOP;
    when "100001" => return DM_LOAD;
    when "100010" => return DM_STORE;
    
    when "010000" => return DC_NOP;
    when "010001" => return DC_JMP;
    when "010100" => return DC_JRA;
    when "010010" => return DC_HLT;
    when "010011" => return DC_INT;
    
    when others   => return DA_NOP; 
   end case;  
  end decodeDebug;
  
  ------- #DEBUG: THIS IS FOR DEBUG NEEDS ONLY, TO SEE COMMAND NAME IN DEBUGGER ------ !!!
  
  function ToInstruction(data : WORD) return Instruction is
    variable cmd : Instruction;
  begin 
    
    cmd.imm      := ToBoolean(data(31));          -- first bit is 'immediate' flag  
    cmd.we       := false;                        -- evaluate this flag later on decode stage!
    cmd.itype    :=         data(29 downto 28);   -- next 2-bit instruction type (3-bit actually, 1 bit is reserved currently)
    cmd.code     :=         data(27 downto 24);   -- next 4 bit for opcodes 
    cmd.reg0     := to_uint(data(23 downto 20));  -- next 4 bits for reg0
    cmd.reg1     := to_uint(data(19 downto 16));  -- next 4 bits for reg1
    cmd.reg2     := to_uint(data(15 downto 12));  -- next 4 bits for reg2 
    cmd.memOffs  :=         data(11 downto 4);
    
    if cmd.itype = INSTR_ALUI then                -- don't use memOffs, read flags instead
      cmd.flags.S  := ToBoolean(cmd.memOffs(6)); 
      cmd.flags.CF := ToBoolean(cmd.memOffs(7));
    end if;
    
    cmd.invalid  := false;  
    cmd.flags.N  := ToBoolean(data(3));           -- last 4 bits for flags
    cmd.flags.Z  := ToBoolean(data(2));
    cmd.flags.LT := ToBoolean(data(1));
    cmd.flags.P  := ToBoolean(data(0));
 
    cmd.cmd := decodeDebug(data(29 downto 24));
  return cmd;   
  
  end ToInstruction;
 
  function GetWriteEnableBit(cmd : Instruction) return boolean is
    variable res : boolean := false;
  begin 
  
    case cmd.itype is
      when INSTR_ALUI =>
        res := (cmd.code /= A_NOP) and (cmd.flags.CF = false); -- if command change flags it does not have to write the register! This is our agreement
      when INSTR_MEM  =>
        res := (cmd.code(1 downto 0) = M_LOAD);
      when INSTR_CNTR =>
        res := false;
      when others     => 
        res := false;
    end case;
    
    return res; 
    
  end GetWriteEnableBit;
 
  function GetRes(afterX : Instruction; aluOut : WORD; memOut : WORD) return WORD is
  begin 
   if afterX.itype = INSTR_ALUI then
     return aluOut;
   else
     return memOut;
   end if; 
  end GetRes;
 
  function GetOpA(afterD : Instruction; afterX : Instruction; xRes : WORD; imm_value : WORD) return WORD is
    variable xA : WORD;
  begin 
  
    if afterX.reg0 = afterD.reg1 and afterX.we then   -- bypass result from X to op1
      xA := xRes;
    else 
      xA := afterD.op1;
    end if;
    
    if (afterD.itype = INSTR_MEM) then                -- alter second op to compute address if mem istruction occured       
      if afterD.imm then 
        xA := imm_value;
      else
        xA := x"000000" & afterD.memOffs(7 downto 0);
      end if;
    end if;
    
    return xA;
    
  end GetOpA;
  
  function GetOpB(afterD : Instruction; afterX : Instruction; xRes : WORD) return WORD is
    variable xA : WORD;
  begin 
    if afterX.reg0 = afterD.reg2 and not afterD.imm and afterX.we then  -- bypass result from X to op2 and ignore bypassing second op for immediate commands
      return xRes;
    else 
      return afterD.op2;
    end if;    
  end GetOpB;
  
  function GetMemOp(cmdX : Instruction) return INSTR_MEM_TYPE is
  begin 
   if cmdX.itype = INSTR_MEM and not cmdX.invalid then 
     return cmdX.code(1 downto 0);    
   else
     return M_NOP;     
   end if;
  end GetMemOp;
  
  function GetAluOp(cmdX : Instruction) return ALU_MEM_TYPE is
  begin
   if cmdX.itype = INSTR_ALUI and not cmdX.invalid then 
     return cmdX.code(3 downto 0);    
   else
     return A_NOP;     
   end if;
  end GetAluOp;

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
  
  signal program  : PROGRAM_MEMORY  := (others => x"00000000"); -- in real implementation this should be out of chip
  signal regs     : REGISTER_MEMORY := (others => x"00000000");
  
  signal imm_value: WORD := x"00000000";
 
  signal flags_Z  : boolean := false; -- Zero
  signal flags_LT : boolean := false; -- Less Than
  signal flags_P  : boolean := false; -- Custom Predicate  
  signal carryOut : std_logic := '0';  
  
  signal highValue : WORD := x"00000000";  
  signal aluOut    : WORD := x"00000000"; -- ALU result
  signal memOut    : WORD := x"00000000"; -- MEM result  
  
  signal halt      : boolean   := false;
  signal memReady  : std_logic := '0';  
  
  signal scoreboard : SCOREBOARD_TYPE := (others => SCOREBOARD_ZERO);
  signal wfifo      : SCOREBOARD_FIFO := (others => SCOREBOARD_ZERO_ELEM);
  
  COMPONENT A1_MMU IS
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
  END COMPONENT;
  
  COMPONENT A1_ALU IS
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
      resHigh  : inout WORD
    );
    
  END COMPONENT;

  signal opA : WORD := x"00000000"; -- bypassed input to ALU or MEM (first operand) 
  signal opB : WORD := x"00000000"; -- bypassed input to ALU or MEM (second operand) 
  signal opR : WORD := x"00000000"; -- result of command after X stage (or M or other).
  
BEGIN 
  
  opR <= GetRes(afterX, aluOut, memOut);
  opA <= GetOpA(afterD, afterX, opR, imm_value);
  opB <= GetOpB(afterD, afterX, opR);
  
  ALU : A1_ALU PORT MAP (clock    => clk, 
                         reset    => rst, 
                         
                         code     => GetAluOp(afterD),
                         flags    => afterD.flags,
                         xA       => opA,
                         xB       => opB,
                         
                         carryOut => carryOut,
                         flags_Z  => flags_Z,
                         flags_LT => flags_LT,
                         
                         resLow   => aluOut,
                         resHigh  => highValue
                         );
  
  MUU: A1_MMU PORT MAP (clock  => clk, 
                        reset  => rst, 
                        optype => GetMemOp(afterD),  
                        addr1  => opA,
                        addr2  => opB,                         
                        input  => afterD.op1,
                        output => memOut,
                        oready => memReady
                       );    
                       
                       
                                             
  ------------------------------------ this process is only for simulation purposes ------------------------------------
  clock : process   
  
  file     file_PROG : text; -- file there the program is located 
  variable v_ILINE   : line;  
  variable v_CMD     : WORD; 
  variable i         : integer := 0; 
  variable j         : integer := 0; 
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
                                   26 => "../../ASM/bin/out026.txt"
                                  );
  
  begin     
    
  for testId in binFiles'low to binFiles'high loop -- 
      
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
     wait for 5 ns; 
     clk  <= not clk;
     i := i+1;
     if halt then
       for i in 0 to 6 loop -- you will need to withdraw 35 ns (7x5=35) from the simulation time to get real execution time.
         wait for 5 ns; 
         clk  <= not clk;
       end loop;
       exit;
     end if;
     
   end loop;   

   ------------------------------------ finish                  ------------------------------------------------- 
   
   if CheckTest(testId, to_sint(regs(0)), to_sint(regs(1)), to_sint(regs(2))) then
     report "TEST " & integer'image(testId) & " PASSED!";
   else
     report "TEST " & integer'image(testId) & " FAILED! " & ": R0 = " & integer'image(to_sint(regs(0))) & ", R1 = " & integer'image(to_sint(regs(1))) & ", R2 = " & integer'image(to_sint(regs(2))); 
   end if;
   
   --exit;
   
   end loop; 
   
   report "end of simulation" severity failure;
   
  end process clock;
  ------------------------------------ this is only for simulation purposes ------------------------------------
    
  main : process(clk,rst)
  
  -------------- fetch input ----------------
  variable cmdF     : Instruction;
  variable rawCmdF  : WORD;             
  variable bubble   : boolean := false;
  variable bubble2  : boolean := false;
  -------------- fetch input ---------------- 
  
  -------------- alu input and internal ----------------  
  variable invalidateNow : boolean := false;
  variable haltNow       : boolean := false;
  -------------- alu input and internal ----------------
  
  -------------- scoreboard ----------------
  variable i : PIPE_COUNT_T := 0;
  variable j : REGT         := 0;
  -------------- scoreboard ----------------
  
  begin           

  if (rst = '1') then

    ip     <= 0;
    afterF <= CMD_NOP; 
    afterD <= CMD_NOP; 
    afterX <= CMD_NOP; 
    halt   <= false;
     
  elsif rising_edge(clk) then     
   
    ------------------------------ instruction fetch and pipeline basics ------------------------------   
    rawCmdF := program(ip);
    cmdF    := ToInstruction(rawCmdF);
    
    haltNow := (cmdF.itype = INSTR_CNTR) and (cmdF.code(2 downto 0) = C_HLT);   
    bubble  := haltNow; 
    bubble2 := false;
    
    ------------------------------ scoreboard ------------------------------ #TODO: check if scoreboard(afterF.reg0) is gt 1 (0 ?). Must bubble in this case. 
    if afterF.we then                                                         
    
      -- (1) scoreboard common tick
      --
      for i in 0 to MAX_PIPE_LEN-1 loop
		    wfifo(i) <= wfifo(i+1);
	    end loop;
      
      for j in 0 to REGT'high loop
        if scoreboard(j) = 0 then
          scoreboard(j) <= 0;
        else
          scoreboard(j) <= scoreboard(j)-1;
        end if;
	    end loop;
    
      -- (2) try to issue command in the pipeline; if can't set "bubble := true;"
      --
      case afterF.itype is    
        when INSTR_ALUI => 
          if wfifo    (ALUI_PIPE_LEN+1).wbn = '0' then            --- identify if there is no WriteBack control hazard 
            wfifo     (ALUI_PIPE_LEN).wbn  <= '1'; 
            wfifo     (ALUI_PIPE_LEN).cmdt <= INSTR_ALUI;
            scoreboard(afterF.reg0)        <= ALUI_PIPE_LEN;            
          else
            bubble2 := true;                                 
          end if;                          
        
        when INSTR_MEM  => 
          if wfifo   (MEM_PIPE_LEN+1).wbn = '0' then             --- identify if there is no WriteBack control hazard
            wfifo    (MEM_PIPE_LEN).wbn  <= '1';  
            wfifo    (MEM_PIPE_LEN).cmdt <= INSTR_MEM; 
            scoreboard(afterF.reg0)      <= MEM_PIPE_LEN;
          else
            bubble2 := true;                                  
          end if;                          
          
        when INSTR_CNTR => 
          if wfifo    (2).wbn = '0' then                          --- identify if there is no WriteBack control hazard
            wfifo     (1).wbn       <= '1'; 
            wfifo     (1).cmdt      <= INSTR_CNTR; 
            scoreboard(afterF.reg0) <= 1;
          else
            bubble2 := true;                                  
          end if;
          
        -- when INSTR_ALUF => 
        -- 
        when others     => 
          null;
          
      end case;
      
    end if;
      
    ------------------------------ scoreboard ------------------------------
    
    halt       <= haltNow;
    imm_value  <= rawCmdF;
    
    if bubble or bubble2 or afterF.imm then -- push nop to afterF in next cycle, cause if afterF is immediate, next instructions is it's data
      afterF <= CMD_NOP;
    else
      afterF <= cmdF;
    end if;
    
    -- 0 1 2 3
    -- F D X W
    --
    
    if bubble2 then 
      afterD    <= afterD;
      afterX    <= CMD_NOP;
    else  
      afterD    <= afterF; 
      afterD.we <= GetWriteEnableBit(afterF);
      afterX    <= afterD;
      
      -- here we have to deal with flags values and predicate commands
      --
      invalidateNow := false;
      if afterD.flags.N or afterD.flags.Z or afterD.flags.LT or afterD.flags.P then       
        invalidateNow := InvalidateCmdIfFlagsDifferent(afterD.flags, flags_Z, flags_LT, flags_P);
        afterX.invalid <= invalidateNow;
        afterX.we      <= afterD.we and not invalidateNow; -- disable write to reg file if command is invalid
      end if;
      
    end if;
    
    ------------------------------ register fetch and bypassing from X to D ---------------------------
    
    if afterX.reg0 = afterF.reg1 and afterX.we then     -- bypass result from X to op1
      afterD.op1 <= opR; 
    else  
      afterD.op1 <= regs(afterF.reg1);                  -- ok, read from register file
    end if; 
    
    if afterF.imm then                                  -- read from instruction memory and ignore bypassing if command is immediate
      afterD.op2 <= rawCmdF; 
    else       
      
      if afterX.reg0 = afterF.reg2 and afterX.we then   -- bypass result from X to op2
        afterD.op2 <= opR; 
      else 
        afterD.op2 <= regs(afterF.reg2);                -- ok, read from register file
      end if;    
      
    end if;
    
    ------------------------------ register fetch and bypassing from X to D ----------------------------
   
   
    ------------------------------ control unit ---------------------------- 
    if bubble or bubble2 then
      ip <= ip;
    elsif (afterD.itype = INSTR_CNTR and not invalidateNow) then
    
      if afterD.code(2 downto 0) = C_JMP  then
        ip <= to_uint(opB);          -- JMP, Jump Absolute Addr
      else
        ip <= to_uint(opB) + ip - 2; -- JRA, Jump Relative Addr
      end if;
    
    else
      ip <= ip+1;
    end if;    
    ------------------------------ control unit ---------------------------- 
    
    ------------------------------ write back ------------------------------   
    if afterX.we and not afterX.invalid then
      regs(afterX.reg0) <= opR;  
    end if;
    ------------------------------ write back ------------------------------ 
   
   
  end if; -- end of rising_edge(clk)
   
  end process main;
 
   
END RTL;

