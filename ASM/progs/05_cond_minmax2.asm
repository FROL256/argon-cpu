r, 1, a, xor, R0, R0, R0
r, 1, a, xor, R1, R1, R1
r, 1, a, xor, R2, R2, R2
i, 1, a, mov, R3 
di, 10
i, 1, a, mov, R4     	
di, 30
i, 1, a, mov, R5     	
di, 4
r, 0, a, cmp, R0, R3, R4  
r, 1, a, mov, R1, R0, R3, 0, 0, if, le
r, 1, a, mov, R1, R0, R4, 0, 0, if, gt
r, 0, a, cmp, R0, R1, R5
r, 1, a, mov, R0, R0, R1, 0, 0, if, le
r, 1, a, mov, R0, R0, R5, 0, 0, if, gt
r, 0, c, hlt, R0, R0, R0
r, 0, c, hlt, R0, R0, R0
r, 0, c, hlt, R0, R0, R0