i, a, mov, R1, R0 
di, 3
i, a, mov, R2, R0
di, 2
r, m, sw,  R0, R2, R2, 255
r, m, sw,  R0, R1, R2, 254  
r, m, lw,  R4, R0, R2, 255   
r, m, lw,  R5, R0, R4, 254
r, a, add, R0, R5, R5
r, a, nop
r, a, nop
r, a, nop
r, c, hlt
r, c, hlt
r, c, hlt