i, 1, a, mov, R3, R0 
di, 16
i, 1, a, mov, R2, R0     	
di, 10
i, 0, m, sw,  R0, R3, R2, 255  
di, 10
i, 1, m, lw,  R0, R0, R2, 254
di, 10
r, 1, a, add, R2, R2, R2  
r, 1, m, lw,  R1, R0, R2, 0 
r, 0, a, nop
r, 0, a, nop
r, 0, a, nop
r, 0, a, nop
r, 0, a, nop
r, 0, c, hlt, R0, R0, R0
r, 0, c, hlt, R0, R0, R0
r, 0, c, hlt, R0, R0, R0