r, 1, a, xor, R0, R0, R0
r, 1, a, xor, R1, R1, R1
i, 1, a, mov, R3 
di, 6
i, 1, a, mov, R1     	
di, 1
i, 1, a, mov, R2     	
di, 1
r, 1, a, mov, R4, R2, R2
r, 1, a, mul, R1, R1, R2
r, 1, a, add, R2, R2, R4 
r, 0, a, cmp, R0, R2, R3
i, 0, c, jmp, R7, R7, R7, 0, 0, if, le
di, 9  
r, 0, a, nop, R0, R0, R0
r, 1, a, add, R0, R1, R3 
r, 0, c, hlt, R0, R0, R0
r, 0, c, hlt, R0, R0, R0
r, 0, c, hlt, R0, R0, R0