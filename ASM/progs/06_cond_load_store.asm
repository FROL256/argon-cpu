r, 1, a, xor, R0, R0, R0
r, 1, a, xor, R1, R1, R1
r, 1, a, xor, R2, R2, R2
i, 1, a, mov, R3 
di, 3
i, 1, a, mov, R4     	
di, 4
i, 1, a, mov, R5     	
di, 5
i, 1, a, mov, R6     	
di, 6
i, 1, a, mov, R7     	
di, 7
r, 0, m, sw,  R0, R4, R3, 10
r, 0, m, sw,  R0, R5, R3, 11
r, 0, a, sub, R2, R3, R4, 0, sf
r, 1, m, lw,  R0, R0, R3, 10, if, gt
r, 1, m, lw,  R1, R0, R3, 10, if, le
r, 1, m, lw,  R8, R0, R3, 10
r, 1, m, lw,  R9, R0, R3, 11
r, 1, a, add, R0, R8, R9
r, 0, a, nop
r, 0, a, nop
r, 0, a, nop
r, 0, a, nop
r, 0, c, hlt, R0, R0, R0
r, 0, c, hlt, R0, R0, R0
r, 0, c, hlt, R0, R0, R0