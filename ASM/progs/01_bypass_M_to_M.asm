i, 1, a, mov, R1 
di, 3
i, 1, a, mov, R2
di, 2
r, 0, m, sw,  R0, R2, R2, 255
r, 0, m, sw,  R0, R1, R2, 254  
r, 1, m, lw,  R4, R0, R2, 255   
r, 1, m, lw,  R5, R0, R4, 254
r, 1, a, add, R0, R5, R5
r, 0, c, hlt
r, 0, c, hlt
r, 0, c, hlt