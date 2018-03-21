i, a, mov, R4 
di, 15
i, a, and, R0, R4
di, 2
i, a, or, R1, R4
di, 256
i, a, xor, R2, R4
dh, 0xFFFFFF0F
r, a, not, R2, R2
r, a, nop, R0, R0, R0
r, c, hlt
r, c, hlt
r, c, hlt