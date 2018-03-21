r, a, xor, R0, R0, R0
r, a, xor, R1, R1, R1
i, a, mov, R3 
di, 6
i, a, mov, R1     	
di, 1
i, a, mov, R2     	
di, 1
r, a, mov, R4, R2, R2
r, a, mul, R1, R1, R2
r, a, add, R2, R2, R4 
r, a, cmp, R0, R2, R3
i, c, jmp, R7, R7, R7, 0, if, le
di, 9  
r, a, nop, R0, R0, R0
r, a, add, R0, R1, R3 
r, c, hlt, R0, R0, R0
r, c, hlt, R0, R0, R0
r, c, hlt, R0, R0, R0