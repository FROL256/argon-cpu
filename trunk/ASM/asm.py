
cmdDict = {'nop' : 0, 
           'mov' : 1, 
		   'add' : 2,
		   'sub' : 3,
		   'adc' : 4,
		   'cmp' : 5,
		   'and' : 6,
		   'or'  : 7,
		   'not' : 8,
		   'xor' : 9,
		   'shl' : 10,
		   'shr' : 11,
		   'mul' : 12, ##########
		   'lw'  : 1,
		   'sw'  : 2,
		   'jmp' : 1,  ##########
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
  
  '''
  r0 = int(tokens[4][1:])
  bits |= (r0 << 20)
  
  if len(tokens) < 6: return bits
  
  r1 = int(tokens[5][1:])
  bits |= (r1 << 16)
  
  if len(tokens) < 7: return bits
  
  r2 = int(tokens[6][1:])
  bits |= (r2 << 12)
  '''
  
  if len(tokens) < 8: return bits
  ## //////////////////////////////////////////////////////////////////////////////////  mem offset
  
  ## //////////////////////////////////////////////////////////////////////////////////  flags
  
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
	
def main():
  
  f = open("add_numbers.asm")
  
  for line in f:
    tokens = line.rstrip().split(',')
    cmdBin = encodeLine(tokens)
    print tokens
    #print cmdBin
  
  f.close()  


main()  
print "Ok"