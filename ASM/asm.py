import ctypes
import sys

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
           'cmp' : 13,           
           'mul' : 15, 
       
           'lw'  : 1,
           'sw'  : 2,
           'swp' : 3,
       
           'jmp' : 1,
           'jra' : 4,  
           'hlt' : 2,
           'int' : 3,}
          
def encodeCommand(tokens):
  
  bits = 0x00000000
  
  ## ////////////////////////////////////////////////////////////////////////////////// imm and we flags
  
  if tokens[0] == 'i':
    bits |= 0x80000000 # set first bit if command is immediate
  
  if len(tokens) < 3: return bits
  ## ////////////////////////////////////////////////////////////////////////////////// instruction type
  
  if tokens[1] == 'a':
    bits |= 0x00000000    # alu is '00'
  elif tokens[1] == 'm':
    bits |= 0x20000000    # mem is '10' 
  elif tokens[1] == 'c':
    bits |= 0x10000000    # ctr is '01'
  elif tokens[1] == 'f':
    bits |= 0x30000000    # fpu is '11'

  if len(tokens) < 3: return bits  
  ## ////////////////////////////////////////////////////////////////////////////////// instruction op code
  
  op = tokens[2]
  if op in cmdDict.keys():
    opCodeMask = (cmdDict[op] << 24)
    bits |= opCodeMask
  
  if len(tokens) < 4: return bits  
  ## //////////////////////////////////////////////////////////////////////////////////  registers
  
  r0 = int(tokens[3][1:])
  bits |= (r0 << 20)
  
  if len(tokens) < 5: return bits
  
  r1 = int(tokens[4][1:])
  bits |= (r1 << 16)
  
  if len(tokens) < 6: return bits
  
  r2 = int(tokens[5][1:])
  bits |= (r2 << 12)
  
  if len(tokens) < 7: return bits
  ## //////////////////////////////////////////////////////////////////////////////////  mem offset, alu specific and cond flags
  
  if tokens[1] == 'a' or tokens[1] == 'c': 
    signedFlag   = 0
    if tokens[6] == 's': 
      signedFlag = 1
    bits |= (signedFlag   << 11)
  elif tokens[1] == 'm':
    memOffs = int(tokens[6])
    if memOffs <= 255:
      bits |= (memOffs << 4)
    
  ## //////////////////////////////////////////////////////////////////////////////////  flags
  cond = ''
  if len(tokens) < 9: 
    return bits
  cond = tokens[8] 
  
  # N,Z,LT,LE,P
  flags = 0
  
  if cond == 'z' or cond == 'eq':
    flags = 4
  elif cond == 'nz' or cond == 'ne':
    flags = 8+4  
  elif cond == 'lt':
    flags = 2
  elif cond == 'le':
    flags = 4+2
  elif cond == 'gt':
    flags = 8+2
  elif cond == 'ge': # ge is impossible to encode unfortunately
    flags = 0
  
  bits |= flags
  
  if len(tokens) < 10: return bits
  cond = tokens[9]
  
  if cond == 'p':
    bits |= 1 # last 'predicate' flag
  
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
    print (tokens)
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

''' BEGIN MAIN PROGRAM '''  
  
if len(sys.argv) > 1:

  path    = sys.argv[1]
  outPath = sys.argv[2]
  main(path, outPath, True)

  print (path + "\t--> " + outPath) 
  
else:

  path = "progs\\01_bypass_X_to_X.asm"
  mainVHDL(path, "out.vhdl") 
  main(path, "out.txt", True)   
  
  print (path + "\t--> Ok")