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
  
  subtype PIPE_ID_TYPE     is STD_LOGIC_VECTOR (1 downto 0);
  subtype INSTR_MEM_TYPE   is STD_LOGIC_VECTOR (1 downto 0);
  subtype ALU_MEM_TYPE     is STD_LOGIC_VECTOR (3 downto 0);
  subtype WHOLE_INSTR_CODE is STD_LOGIC_VECTOR (5 downto 0);
  
  ----------------------------------------------------------------------------------------------------------------------- scoreboard parameters
  constant MAX_PIPE_LEN : integer := 3;                       -- allow max 3 stages of the pipeline, can be changed easily.
  subtype  PIPE_COUNT_T is integer range 0 to MAX_PIPE_LEN-1; -- per register counter type
 
  type PIPE_ELEM is record
    wbn : boolean;         -- write back now
    pid : PIPE_ID_TYPE;    -- pipe id
    reg : REGT;
  end record;
  
  type     SCOREBOARD_TYPE is array (0 to REGT'high)    of PIPE_COUNT_T;  -- array of per-register counters
  type     SCOREBOARD_PLEN is array (0 to 3)            of PIPE_COUNT_T;  -- stores pipe length for each pipe
  type     SCOREBOARD_FIFO is array (0 to MAX_PIPE_LEN) of PIPE_ELEM;     -- fifo to solve Write Back structural hazard and store command pipe id
  
  constant ALUI_PIPE_LEN   : PIPE_COUNT_T := 1;
  constant MEM_PIPE_LEN    : PIPE_COUNT_T := 2;
  constant CTR_PIPE_LEN    : PIPE_COUNT_T := 1;
  constant PIPE_ZERO_ELEM  : PIPE_ELEM    := (wbn => false, pid => "00", reg => 0);
  ----------------------------------------------------------------------------------------------------------------------- scoreboard parameters
  
  constant CACHE_MISS_STALL_CLOCKS : integer := 8; -- We must know how long we have to wait MEM command if cache miss happened.
  constant CACHE_MISS_WAIT_CLOCKS  : integer := CACHE_MISS_STALL_CLOCKS-2;
  
  constant INSTR_ALUI : PIPE_ID_TYPE := "00";
  constant INSTR_CNTR : PIPE_ID_TYPE := "01";
  constant INSTR_MEM  : PIPE_ID_TYPE := "10"; 
  constant INSTR_ALUF : PIPE_ID_TYPE := "11";
 
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
  constant A_CMP   : STD_LOGIC_VECTOR(3 downto 0) := "1101"; -- 
  constant A_NN3   : STD_LOGIC_VECTOR(3 downto 0) := "1110";
  constant A_MUL   : STD_LOGIC_VECTOR(3 downto 0) := "1111";
            
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
                         DA_MFH, DA_MUL, DA_CMP, DA_NN2,
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
  
  -- ALUI: 
  --
  -- F    F    F  F  F  FF  F
  -- 0000 CODE R0 R1 R2 00  FLAGS    R-type instruction; r, a, add, R0, R1, R2  
  -- 1000 CODE R0 R1 0  00  FLAGS    I-type instruction; i, a, add, R0, R1, 
  --                                                     d, {-655362345}   
 
  -- MEM: 
  --
  -- F      F    F F  F  FF     F
  -- 0010 0 CODE 0 R1 [R2+OFFS] FLAGS  R-type instruction; r, m, sw, 0, R1, R2, 255    // mem(R2+255) := R1;
  -- 1010 0 CODE 0 R1 [R2+OFFS] FLAGS  I-type instruction; i, m, sw, 0, R1, R2, 255    // mem(R2+255) := -655362345; 
  --                                                       d, {-655362345}             //            
  --                                                       r, 1, m, lw R0, 0, R2, 255  // R0 := mem(R2+255);
                                                       
  -- CONTROL:  
  -- F    F    F F  F  FF    F                                              
  -- 0001 CODE 0 R1 0  00    FLAGS  R-type instruction; r, c, jmp, 0, 0, R2 // jmp [R2]
  -- 1001 CODE 0 0  0  00    FLAGS  I-type instruction; i, c, jmp           // jmp [ADDRESS]
  --                                                    d, {ADDRESS}
 
  -- FLOAT:
  -- 0011  ... same as for ALUI.
  
  -- OPCODE = "00" & CODE where "00" is instruction type
  --
  type Instruction is record
    cmd     : DEBUG_COMMAND;                -- #DEBUG: THIS IS ONLY FOR DEBUG NEEDS!!!
    reg0    : REGT;
    reg1    : REGT;
    reg2    : REGT; 
    imm     : boolean;                      -- immediate flag          
    we      : boolean;                      -- write enable
    itype   : PIPE_ID_TYPE;                    -- instruction type/pipe_id  
    code    : STD_LOGIC_VECTOR(3 downto 0); -- instruction op-code   
    memOffs : STD_LOGIC_VECTOR(7 downto 0); -- used only by memory instructions 
    flags   : Flags;                        -- predicates
    op1     : WORD;
    op2     : WORD;
  end record;        
  
  constant CMD_NOP : Instruction := (imm => false, we=>false, code => "0000", itype=> "00", reg0 => 0, reg1 => 0, reg2 => 0, 
                                     memOffs => x"00", flags => (others => false), 
                                     op1 => x"00000000", op2 => x"00000000", 
                                     cmd => DA_NOP);
  
  function ToInstruction(data : WORD) return Instruction; 
  function ToStdLogic(L: BOOLEAN) return std_logic; 
  function ToBoolean(L: std_logic) return BOOLEAN; 
  function InvalidateCmdIfFlagsDifferent(cmdxflags : Flags; flags_Z : boolean; flags_LT : boolean; flags_P : boolean) return boolean;
  function InvalidCommand(afterD : Instruction; flags_Z : boolean; flags_LT : boolean; flags_P : boolean) return boolean;
  function NeedReg1(cmd : Instruction) return boolean;
  function NeedReg2(cmd : Instruction) return boolean;  
  function GetWriteEnableBit(cmd : Instruction) return boolean;
  
  function GetRes(rtype  : PIPE_ID_TYPE; aluOut : WORD; memOut : WORD) return WORD;
  function GetOpA(afterD : Instruction; afterX : PIPE_ELEM; xRes : WORD) return WORD;
  function GetOpB(afterD : Instruction; afterX : PIPE_ELEM; xRes : WORD) return WORD;
  function GetAddrOffset(afterD : Instruction; imm_value : WORD) return WORD;
  
  function GetMemOp(cmd : Instruction; isInvalid : boolean) return INSTR_MEM_TYPE;
  function GetAluOp(cmd : Instruction) return ALU_MEM_TYPE;
                            
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
    when "001101" => return DA_CMP;
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
    cmd.itype    :=         data(29 downto 28);   -- next 3-bit instruction type / pipe id 
    cmd.code     :=         data(27 downto 24);   -- next 4 bit for opcodes 
    cmd.reg0     := to_uint(data(23 downto 20));  -- next 4 bits for reg0
    cmd.reg1     := to_uint(data(19 downto 16));  -- next 4 bits for reg1
    cmd.reg2     := to_uint(data(15 downto 12));  -- next 4 bits for reg2 
    cmd.memOffs  :=         data(11 downto 4);    -- next 8 bits for mem offs 
    
    if cmd.itype = INSTR_ALUI then                -- don't use memOffs, read flags instead
      cmd.flags.S  := ToBoolean(cmd.memOffs(7)); 
      
      if cmd.code = A_CMP then
        cmd.code     := A_SUB;
        cmd.flags.CF := true;
      else
        cmd.flags.CF := false;
      end if;
      
    end if;
    
    cmd.flags.N  := ToBoolean(data(3));           -- last 4 bits for flags
    cmd.flags.Z  := ToBoolean(data(2));
    cmd.flags.LT := ToBoolean(data(1));
    cmd.flags.P  := ToBoolean(data(0));
 
    cmd.cmd := decodeDebug(data(29 downto 24));
  return cmd;   
  
  end ToInstruction;
 
  function GetWriteEnableBit(cmd : Instruction) return boolean is
  begin 
    case cmd.itype is
      when INSTR_ALUI => return (cmd.code /= A_NOP) and (cmd.flags.CF = false); -- if command change flags it does not have to write the register! This is our agreement
      when INSTR_MEM  => return (cmd.code(1 downto 0) = M_LOAD);
      when INSTR_CNTR => return false;
      when others     => return false;
    end case;
  end GetWriteEnableBit;
 
  function GetRes(rtype : PIPE_ID_TYPE; aluOut : WORD; memOut : WORD) return WORD is
  begin 
   if rtype = INSTR_ALUI then
     return aluOut;
   else
     return memOut;
   end if; 
  end GetRes;
 
  function GetOpA(afterD : Instruction; afterX : PIPE_ELEM; xRes : WORD) return WORD is
  begin 
  
    if afterX.reg = afterD.reg1 and afterX.wbn then   -- bypass result from X to op1
      return xRes;
    else 
      return afterD.op1;
    end if;   
    
  end GetOpA;
  
  function GetAddrOffset(afterD : Instruction; imm_value : WORD) return WORD is
     variable xA : WORD;
  begin 
       
    if afterD.imm then 
      return imm_value;
    else
      return x"000000" & afterD.memOffs(7 downto 0);
    end if;
    
  end GetAddrOffset;
  
  function GetOpB(afterD : Instruction; afterX : PIPE_ELEM; xRes : WORD) return WORD is
    variable xA : WORD;
  begin 
    if afterX.reg = afterD.reg2 and not afterD.imm and afterX.wbn then  -- bypass result from X to op2 and ignore bypassing second op for immediate commands
      return xRes;
    else 
      return afterD.op2;
    end if;    
  end GetOpB;
  
  function GetMemOp(cmd : Instruction; isInvalid : boolean) return INSTR_MEM_TYPE is
  begin 
   if cmd.itype = INSTR_MEM and not isInvalid then -- #TODO: test isInvalid case; create test program; it is untested currently !!!!
     return cmd.code(1 downto 0);    
   else
     return M_NOP;     
   end if;
  end GetMemOp;
  
  function GetAluOp(cmd : Instruction) return ALU_MEM_TYPE is
  begin
   if cmd.itype = INSTR_ALUI then 
     return cmd.code(3 downto 0);    
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
  
  function InvalidCommand(afterD : Instruction; flags_Z : boolean; flags_LT : boolean; flags_P : boolean) return boolean is
  begin 
    if afterD.flags.N or afterD.flags.Z or afterD.flags.LT or afterD.flags.P then       
      return InvalidateCmdIfFlagsDifferent(afterD.flags, flags_Z, flags_LT, flags_P);
    else
      return false;
    end if;
  end InvalidCommand;
  
  function NeedReg1(cmd : Instruction) return boolean is 
  begin
    return not ( (cmd.itype = INSTR_MEM) and (cmd.code(1 downto 0) = M_LOAD) );
  end NeedReg1;
  
  function NeedReg2(cmd : Instruction) return boolean is 
  begin
    return not cmd.imm and not (cmd.itype = INSTR_ALUI and(cmd.code(3 downto 0) = A_MOV));
  end NeedReg2;
  
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

use STD.textio.all;             -- for reading files
use ieee.std_logic_textio.all;  -- for reading files

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
  
  signal ipM1 : integer range 0 to PROGRAM_MEMORY'high := 0;
  signal ipM2 : integer range 0 to PROGRAM_MEMORY'high := 0;
  
  signal afterF : Instruction := CMD_NOP; 
  signal afterD : Instruction := CMD_NOP; 
  
  signal program  : PROGRAM_MEMORY  := (others => x"00000000"); -- in real implementation this should be out of chip
  signal regs     : REGISTER_MEMORY := (others => x"00000000");
  
  signal imm_value: WORD := x"00000000";
 
  signal flags_Z       : boolean := false; -- Zero
  signal flags_LT      : boolean := false; -- Less Than
  signal flags_P       : boolean := false; -- Custom Predicate  
  signal carryOut      : std_logic := '0';  
  signal invalidAfterD : boolean   := false;
  
  signal highValue  : WORD := x"00000000";  
  signal aluOut     : WORD := x"00000000"; -- ALU result
  signal memOut     : WORD := x"00000000"; -- MEM result 
  signal memInputOp : STD_LOGIC_VECTOR(1 downto 0) := "00";   
  
  signal halt          : boolean   := false;
  signal memReady      : std_logic := '0'; 
  
  -- stall caused by cache miss; re-issue load/store instruction that cause cache miss and then bubble for predefined clocks number;
  --
  signal cmStall       : boolean   := false;
  signal cmStallCouter : integer range 0 to CACHE_MISS_WAIT_CLOCKS := 0;  
  
  signal   scoreboard : SCOREBOARD_TYPE := (others => 0);
  signal   wpipe      : SCOREBOARD_FIFO := (others => PIPE_ZERO_ELEM);
  constant pipe_len   : SCOREBOARD_PLEN := (ALUI_PIPE_LEN, CTR_PIPE_LEN, MEM_PIPE_LEN, 0); -- pipe length table (get pipe length by pipe id)
  
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
  
  signal aOffs : WORD := x"00000000";
  
BEGIN 
  
  -- bypass values
  --
  opR   <= GetRes(wpipe(0).pid, aluOut, memOut);
  opA   <= GetOpA(afterD, wpipe(0), opR);
  opB   <= GetOpB(afterD, wpipe(0), opR);
  aOffs <= GetAddrOffset(afterD, imm_value);
  
  -- here we have to deal with flags values and predicate commands
  --
  invalidAfterD <= InvalidCommand(afterD, flags_Z, flags_LT, flags_P);
  
  -- put other modules here
  --
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
  
  cmStall    <= not ToBoolean(memReady);                    
  memInputOp <= GetMemOp(afterD, invalidAfterD);
  
  MUU: entity work.A1_MMU(TWO_CLOCK_ALWAYS) -- (TWO_CLOCK_ALWAYS, CACHE_MISS_SIM)
              PORT MAP (clock  => clk, 
                        reset  => rst, 
                        optype => memInputOp,  
                        addr1  => aOffs,
                        addr2  => opB,                         
                        input  => opA, 
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
  
  type testtype is array (1 to 28) of string(1 to 24);
  
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
                                   27 => "../../ASM/bin/out027.txt",
                                   28 => "../../ASM/bin/out028.txt"
                                  );
  
  begin     
    
  for testId in binFiles'low to binFiles'high loop -- binFiles'low
      
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
  variable rawCmdF : WORD;             
  variable bubble  : boolean := false;
  -------------- fetch input ---------------- 
  
  -------------- scoreboard ----------------
  variable i       : PIPE_COUNT_T := 0;
  variable j       : REGT         := 0;
  variable no_waw  : boolean      := false;
  variable plen    : PIPE_COUNT_T := 0;
  -------------- scoreboard ----------------
  
  begin           

  if (rst = '1') then

    ip     <= 0;
    afterF <= CMD_NOP; 
    afterD <= CMD_NOP; 
    halt   <= false;
     
  elsif rising_edge(clk) then     
        
    ------------------------------ scoreboard ------------------------------   
    -- scoreboard tick
    --
    for i in 0 to MAX_PIPE_LEN-1 loop
      wpipe (i) <= wpipe (i+1);
    end loop;
      
    for j in 0 to REGT'high loop
      if scoreboard(j) = 0 then
        scoreboard(j) <= 0;
      else
        scoreboard(j) <= scoreboard(j)-1;
      end if;
    end loop;
    
    -- try to issue command in the pipeline; if can't set "bubble := true;"
    -- "0" in scoreboard means input registers are already written; 
    -- "1" in scoreboard means result is going to be written and can be bypassed right now from "opR"; 
    -- "2" (and greater) in scoreboard means result is not ready.
    --
    bubble := ( (scoreboard(afterD.reg1) > 1 and NeedReg1(afterD) ) or 
                (scoreboard(afterD.reg2) > 1 and NeedReg2(afterD) ) );  -- detect RAW  
                
    if afterD.we and not bubble then                                                         
      
      plen   := pipe_len(to_uint(afterD.itype));    --- 
      no_waw := (scoreboard(afterD.reg0) <= plen);  ---                 -- detect WAW
      
      if wpipe(plen  ).wbn = false and no_waw then  --- identify if there is no WriteBack control hazard 
        wpipe (plen-1).wbn      <= not invalidAfterD;  
        wpipe (plen-1).reg      <= afterD.reg0;              
        wpipe (plen-1).pid      <= afterD.itype;                             
        scoreboard(afterD.reg0) <= plen;             
      else                                                            
        bubble := true;                                               
      end if;                                              
      
    end if;
    
    bubble := bubble or (cmStallCouter > 0); 
    ------------------------------ scoreboard ------------------------------
    
    ------------------------------ instruction fetch and pipeline basics ------------------------------   
    rawCmdF := program(ip);

    imm_value  <= rawCmdF;
    halt       <= halt or ( ((afterF.itype = INSTR_CNTR) and (afterF.code(2 downto 0) = C_HLT)) and (cmStallCouter = 0) );
    
    if bubble then 
    
      if cmStallCouter /= 0 then
        afterF <= CMD_NOP;
        afterD <= CMD_NOP;
      else     
        afterF <= afterF;
        afterD <= afterD;
      end if;
      
      -- if stall happened then there is an opportunity to loose register that is not yet written to the register file. 
      -- This happens due to we don't actually repeat reading from register file when "afterD <= afterD" happened.
      -- So even if we does have correct value in the register file, we will not read it during simple "afterD <= afterD" assignment, right? :)
      -- Thus, we must check result each clock during stall and bypass it from opR (via opA and opB signals) to afterD.op1 or afterD.op2 if possible.     
      --
      afterD.op1 <= opA;
      afterD.op2 <= opB;
      
    else  
    
      if afterF.imm then -- push nop to afterF in next cycle, cause if afterF is immediate, next instructions is it's data
        afterF <= CMD_NOP;
      else
        afterF <= ToInstruction(rawCmdF);
      end if;
      
      afterD    <= afterF; 
      afterD.we <= GetWriteEnableBit(afterF);     
      
      ------------------------------ register fetch and bypassing from X to D ---------------------------
      if wpipe(0).reg = afterF.reg1 and wpipe(0).wbn then -- bypass result from X to op1
        afterD.op1 <= opR; 
      else  
        afterD.op1 <= regs(afterF.reg1);                      -- ok, read from register file
      end if; 
      
      if afterF.imm then                                      -- read from instruction memory and ignore bypassing if command is immediate
        afterD.op2 <= rawCmdF; 
      else       
        
        if wpipe(0).reg = afterF.reg2 and wpipe(0).wbn then   -- bypass result from X to op2
          afterD.op2 <= opR; 
        else 
          afterD.op2 <= regs(afterF.reg2);                    -- ok, read from register file
        end if;    
        
      end if;  
      ------------------------------ register fetch and bypassing from X to D ----------------------------
      
    end if;  
   
    
    ------------------------------ control unit ---------------------------- 
    
    -- remember instruction address that we probably have to reissue in future if cache miss occur
    --
    if afterD.itype = INSTR_MEM then 
      ipM1 <= ip - 2;                           
    else
      ipM1 <= ipM1;
    end if;
    ipM2 <= ipM1;
    
    -- process cache miss wait/stall counter
    --
    if cmStall and cmStallCouter = 0 then
      cmStallCouter <= CACHE_MISS_WAIT_CLOCKS;
    elsif cmStallCouter /= 0 then
      cmStallCouter <= cmStallCouter-1;
    else
      cmStallCouter <= 0;
    end if;
    
    -- main part of control unit; process instruction pointer (ip).
    --
    if cmStall and cmStallCouter = 0 then                
      ip <= ipM2;    
    elsif halt or bubble then
      ip <= ip;
    elsif (afterD.itype = INSTR_CNTR and not invalidAfterD) then
    
      if afterD.code(2 downto 0) = C_JMP  then
        ip <= to_uint(opB);          -- JMP, Jump Absolute Addr
      elsif  afterD.code(2 downto 0) = C_JRA  then
        ip <= to_uint(opB) + ip - 2; -- JRA, Jump Relative Addr
      else
        ip <= ip+1;                  -- can be undefined instruction for some reason.
      end if;
      
    else
      ip <= ip+1;
    end if;    
    ------------------------------ control unit ---------------------------- 
    
    ------------------------------ write back ------------------------------       
    if wpipe(0).wbn and (not cmStall) and (cmStallCouter = 0) then
      regs(wpipe(0).reg) <= opR;  
    end if;
    ------------------------------ write back ------------------------------ 
    
  end if; -- end of rising_edge(clk)
   
  end process main;
 
END RTL;

