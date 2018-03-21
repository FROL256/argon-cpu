i, a, mov, R1, R0 
di, 4
i, a, mov, R2, R0
di, 5
r, m, sw,  R0, R1, R2, 255  
r, m, lw,  R4, R0, R2, 255   
r, a, nop
r, a, add, R0, R4, R4
r, a, nop
r, a, nop
r, c, hlt
r, c, hlt
r, c, hlt