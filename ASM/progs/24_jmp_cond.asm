r, a, xor, R0, R0, R0
r, a, xor, R1, R1, R1
r, a, xor, R2, R2, R2
i, a, mov, R3 
di, 3
i, a, mov, R4     	
di, 4
r, a, cmp, R0, R3, R4
i, c, jmp, R7, R7, R7, 0, if, gt
di, 17  
r, a, nop, R0, R0, R0
r, a, add, R2, R3, R4
i, c, jmp, R7, R7, R7, 0, if, le
di, 16  
r, a, nop, R0, R0, R0
r, a, add, R1, R3, R2
r, a, add, R0, R1, R2 
r, c, hlt, R0, R0, R0
r, c, hlt, R0, R0, R0
r, c, hlt, R0, R0, R0