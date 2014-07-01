i, 1, a, mov, R3 
di, 3
i, 1, a, mov, R2     	
di, 10
r, 0, m, sw,  R0, R3, R2, 255  
r, 1, m, lw,  R0, R0, R2, 255  
r, 1, m, lw,  R1, R0, R2, 255 
r, 0, c, hlt, R0, R0, R0
r, 0, c, hlt, R0, R0, R0
r, 0, c, hlt, R0, R0, R0