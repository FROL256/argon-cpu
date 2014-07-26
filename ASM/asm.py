import ctypes

cmdDict = {'nop' : 0, 
           'shl' : 1, 
           'shr' : 2,
           'mov' : 3,
           'add' : 4,
           'adc' : 5,
           'sub' : 6,
           'sbc' : 7,
           'and' : 8,
           'or'  : 9,
           'not' : 10,
           'xor' : 11,
           'mfh' : 12, 
           'mul' : 15, 
		   
           'lw'  : 1,
           'sw'  : 2,
		   
           'jmp' : 1,  
           'hlt' : 2,
           'int' : 3}
   		   
def encodeCommand(tokens):
  
  bits = 0x00000000
  
  ## ////////////////////////////////////////////////////////////////////////////////// imm and we flags
  
  if tokens[0] == 'i':
    bits |= 0x80000000 # set first bit if command is immediate
  
  if tokens[1] == '1':
    bits |= 0x40000000 # set second bit if command has write enable flag
  
  if len(tokens) < 3: return bits
  ## ////////////////////////////////////////////////////////////////////////////////// instruction type
  
  if tokens[2] == 'a':
    bits |= 0x00000000    # alu is '00'
  elif tokens[2] == 'm':
    bits |= 0x20000000    # mem is '10' 
  elif tokens[2] == 'c':
    bits |= 0x10000000    # crl is '01'
  elif tokens[2] == 'f':
    bits |= 0x30000000    # mem is '11'

  if len(tokens) < 4: return bits	
  ## ////////////////////////////////////////////////////////////////////////////////// instruction op code
  
  op = tokens[3]
  if cmdDict.has_key(op):
    opCodeMask = (cmdDict[op] << 24)
    bits |= opCodeMask
  
  if len(tokens) < 5: return bits	
  ## //////////////////////////////////////////////////////////////////////////////////  registers
  
  r0 = int(tokens[4][1:])
  bits |= (r0 << 20)
  
  if len(tokens) < 6: return bits
  
  r1 = int(tokens[5][1:])
  bits |= (r1 << 16)
  
  if len(tokens) < 7: return bits
  
  r2 = int(tokens[6][1:])
  bits |= (r2 << 12)
  
  if len(tokens) < 8: return bits
  ## //////////////////////////////////////////////////////////////////////////////////  mem offset, alu specific and cond flags
  
  cond = ''
  if tokens[2] == 'a': 
    signedFlag   = 0
    setFlagsFlag = 0
    if tokens[7] == 's': 
      signedFlag = 1
    if len(tokens) >= 9:
      if tokens[8] == 'sf':
        setFlagsFlag = 1
	
    bits |= (signedFlag << 11)
    bits |= (setFlagsFlag << 10)
	
    if len(tokens) < 11: return bits
    cond = tokens[10]
	
  else:
    memOffs = int(tokens[7])
    if memOffs <= 255:
      bits |= (memOffs << 4)
  
    if len(tokens) < 10: return bits
    cond = tokens[9]
	  
  ## //////////////////////////////////////////////////////////////////////////////////  flags
  
  # N,Z,LT,LE
  flags = 0
  
  if cond == 'z' or cond == 'eq':
    flags = 4
  elif cond == 'nz' or cond == 'ne':
    flags = 8+4	
  elif cond == 'lt':
    flags = 2
  elif cond == 'gt':
    flags = 8+1
  elif cond == 'ge':
    flags = 8+2
  elif cond == 'le':
    flags = 1
  
  bits |= flags
  
  return bits

def encodeLine(tokens):
  
  if len(tokens) <= 1:
    return 0

  if tokens[0] == "di":
    return int(tokens[1]) 
  elif tokens[0] == "dh":
    return int(tokens[1], 16)
  elif tokens[0] == "df":
    return float(tokens[1])
  else:
    return encodeCommand(tokens)
	
def main(inFileName, outFileName, isBinary):
  
  openFileParams = "w"
  #if isBinary: openFileParams = "wb"
  
  f = open(inFileName)
  o = open(outFileName, openFileParams)
  
  for line in f:
    tokens = line.rstrip().replace(" ", "").split(',')
    #print tokens
    cmdBin = encodeLine(tokens)
	
    if isBinary:
      bitStr = bin(cmdBin)[2:]
      o.write(bitStr.zfill(32))
      o.write("\n")
    else:
      strHex = hex(cmdBin)
      if strHex[-1] == 'L':
        strHex = strHex[:-1]
      o.write(strHex)
      o.write("\n")
  
  f.close()  
  o.close()

def mainVHDL(inFileName, outFileName):
  
  f = open(inFileName)
  o = open(outFileName, "w")
  
  o.write('signal program : PROGRAM_MEMORY := \n');
  o.write('  ( \n');
  
  i = 0
  for line in f:
    tokens = line.rstrip().replace(" ", "").split(',')
    print tokens
    cmdBin = encodeLine(tokens)
    strHex = hex(cmdBin)
	
    if strHex[-1] == 'L':
      strHex = strHex[:-1]
	
    if len(strHex) < 8:
      strHex = strHex + "0" * (10 - len(strHex))
    
    o.write("  " + str(i) + " => x\"" + strHex[2:] + "\",\n")
    i = i+1
  
  o.write('  others => x"00000000" \n');
  o.write('  ); \n');
  f.close()  
  o.close()  

path = "progs\\01_bypass_X_to_X.asm"
 
mainVHDL(path, "out.vhdl") 
main(path, "out.txt", True)   
print "Ok"