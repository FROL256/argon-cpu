r, a, xor, R0, R0, R0
r, a, xor, R1, R1, R1
r, a, xor, R2, R2, R2
i, a, mov, R3 
di, 3
i, a, mov, R4     	
di, 4
i, a, mov, R5     	
di, 5
i, a, mov, R6     	
di, 6
i, a, mov, R7     	
di, 7
r, m, sw,  R0, R4, R3, 10
r, m, sw,  R0, R5, R3, 11
r, a, cmp, R2, R3, R4
r, m, lw,  R0, R0, R3, 10, if, gt
r, m, lw,  R1, R0, R3, 10, if, le
r, m, lw,  R8, R0, R3, 10
r, m, lw,  R9, R0, R3, 11
r, a, add, R0, R8, R9
r, a, nop
r, a, nop
r, a, nop
r, a, nop
r, c, hlt, R0, R0, R0
r, c, hlt, R0, R0, R0
r, c, hlt, R0, R0, R0