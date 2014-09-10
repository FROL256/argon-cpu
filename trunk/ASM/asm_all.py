import os

os.system("asm.py add_numbers.asm bin/out001.txt")
os.system("asm.py load_store.asm  bin/out002.txt")
os.system("asm.py progs/01_bypass_D_to_X.asm bin/out003.txt")
os.system("asm.py progs/01_bypass_M_to_D.asm bin/out004.txt")
os.system("asm.py progs/01_bypass_M_to_M.asm bin/out005.txt")
os.system("asm.py progs/01_bypass_M_to_X.asm bin/out006.txt")
os.system("asm.py progs/01_bypass_X_to_X.asm bin/out007.txt")
os.system("asm.py progs/02_add_sint32_neg.asm bin/out008.txt")
os.system("asm.py progs/02_add_uint64.asm bin/out009.txt")
os.system("asm.py progs/02_logic_ops.asm bin/out010.txt")