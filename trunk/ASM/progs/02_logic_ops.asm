i, 1, a, mov, R4 
di, 15
i, 1, a, and, R0, R4
di, 2
i, 1, a, or, R1, R4
di, 256
i, 1, a, xor, R2, R4
dh, 0xFFFFFF0F
r, 1, a, not, R2, R2
r, 0, a, nop, R0, R0, R0
r, 0, c, hlt
r, 0, c, hlt
r, 0, c, hlt