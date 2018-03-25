r, a, xor, R0, R0, R0
r, a, xor, R1, R1, R1
r, a, xor, R2, R2, R2
i, a, mov, R3 
di, 10
i, a, mov, R4     	
di, 30
i, a, mov, R5     	
di, 4
r, a, cmp, R0, R3, R4  
r, a, mov, R1, R0, R3, 0, if, le
r, a, mov, R1, R0, R4, 0, if, gt
r, a, cmp, R0, R1, R5
r, a, mov, R0, R0, R1, 0, if, le
r, a, mov, R0, R0, R5, 0, if, gt
r, c, hlt, R0, R0, R0
r, c, hlt, R0, R0, R0
r, c, hlt, R0, R0, R0