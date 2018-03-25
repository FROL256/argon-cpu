i, a, mov, R3, R0 
di, 3
i, a, mov, R2, R0     	
di, 10
r, m, sw,  R0, R3, R2, 255  
r, m, lw,  R0, R0, R2, 255  
r, m, lw,  R1, R0, R2, 255 
r, a, nop
r, a, nop
r, a, nop
r, a, nop
r, c, hlt, R0, R0, R0
r, c, hlt, R0, R0, R0
r, c, hlt, R0, R0, R0