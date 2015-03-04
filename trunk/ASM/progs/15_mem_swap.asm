r, 1, a, xor, R0, R0, R0
r, 1, a, xor, R1, R1, R1
r, 1, a, xor, R2, R2, R2
i, 1, a, mov, R3, R0 
di, 3
i, 1, a, mov, R4, R0 
di, 4
i, 1, a, mov, R1, R0 
di, 5
i, 1, a, mov, R2, R0     	
di, 10
r, 0, m, sw,  R0, R3, R2, 255  
r, 1, m, swp, R1, R1, R2, 255  
r, 1, m, lw,  R0, R0, R2, 255
r, 0, a, nop, R0, R0, R0
r, 0, a, nop, R0, R0, R0
r, 0, a, nop, R0, R0, R0 
r, 0, c, hlt, R0, R0, R0
r, 0, c, hlt, R0, R0, R0
r, 0, c, hlt, R0, R0, R0