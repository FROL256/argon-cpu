r, a, xor, R0, R0, R0
r, a, xor, R1, R1, R1
i, a, mov, R2, R0     	
di, 1
r, m, sw,  R0, R1, R1, 10
r, a, add, R1, R1, R2 
r, m, sw,  R0, R1, R1, 10
r, a, add, R1, R1, R2 
r, m, sw,  R0, R1, R1, 10
r, a, add, R1, R1, R2 
r, m, sw,  R0, R1, R1, 10
r, a, add, R1, R1, R2 
r, m, sw,  R0, R1, R1, 10
r, a, xor, R0, R0, R0 
r, a, xor, R5, R5, R5
r, m, lw,  R3, R0, R1, 10
r, a, add, R0, R0, R3
r, a, cmp, R0, R1, R5
i, c, jmp, R9, R9, R9, 0, if, gt
di, 15
r, a, sub, R1, R1, R2  
r, c, hlt, R0, R0, R0
r, c, hlt, R0, R0, R0
r, c, hlt, R0, R0, R0