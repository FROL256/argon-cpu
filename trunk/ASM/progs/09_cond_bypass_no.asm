r, 1, a, xor, R0, R0, R0
r, 1, a, xor, R1, R1, R1
r, 1, a, xor, R2, R2, R2
i, 1, a, mov, R3 
di, 3
i, 1, a, mov, R4     	
di, 4
r, 0, a, sub, R0, R3, R4, 0, sf  
r, 1, a, add, R2, R3, R4, 0, 0, if, gt
r, 1, a, add, R1, R3, R2, 0, 0, if, le
r, 1, a, add, R0, R1, R2, 0, 0, if, lt  
r, 0, c, hlt, R0, R0, R0
r, 0, c, hlt, R0, R0, R0
r, 0, c, hlt, R0, R0, R0