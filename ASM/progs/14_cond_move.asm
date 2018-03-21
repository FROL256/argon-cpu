r, a, xor, R0, R0, R0
i, a, mov, R1 
di, 15
i, a, mov, R2     	
di, 10
r, a, cmp, R0, R2, R2  
r, a, mov, R0, R0, R2, 0, if, z
r, a, mov, R0, R0, R1, 0, if, nz  
r, c, hlt, R0, R0, R0
r, c, hlt, R0, R0, R0
r, c, hlt, R0, R0, R0