r, 0, a, xor, R0, R0, R0
i, 1, a, mov, R1 
di, 15
i, 1, a, mov, R2     	
di, 10
r, 0, a, cmp, R0, R2, R2  
r, 1, a, mov, R0, R0, R2, 0, 0, if, z
r, 1, a, mov, R0, R0, R1, 0, 0, if, nz  
r, 0, c, hlt, R0, R0, R0
r, 0, c, hlt, R0, R0, R0
r, 0, c, hlt, R0, R0, R0