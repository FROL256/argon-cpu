i, a, mov, R3, R0 
di, 16
i, a, mov, R2, R0     	
di, 10
i, m, sw,  R0, R3, R2, 255  
di, 10
i, m, lw,  R0, R0, R2, 254
di, 10
r, a, add, R2, R2, R2  
r, m, lw,  R1, R0, R2, 0 
r, a, nop
r, a, nop
r, a, nop
r, a, nop
r, a, nop
r, c, hlt, R0, R0, R0
r, c, hlt, R0, R0, R0
r, c, hlt, R0, R0, R0