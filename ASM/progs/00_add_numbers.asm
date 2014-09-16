r, 1, a, xor, R0, R0, R0
i, 1, a, or,  R1, R0, R0 
dh, 0x00000003
i, 1, a, or,  R2, R0, R0
di, 2
r, 1, a, add, R0, R1, R2
r, 0, c, hlt
r, 0, c, hlt
r, 0, c, hlt