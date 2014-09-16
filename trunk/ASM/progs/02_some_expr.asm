r, 1, a, xor, R0, R0, R0
i, 1, a, mov, R4 
di, 16
i, 1, a, mov, R5
di, 2
i, 1, a, mov, R6
di, 256
r, 1, a, shl, R2, R5
r, 1, a, shr, R3, R4
r, 1, a, add, R3, R2, R3
r, 1, a, mul, R2, R2, R3
i, 1, a, sub, R1, R2
di, 39
r, 1, a, mov, R0, R1, R1 
r, 0, c, hlt
r, 0, c, hlt
r, 0, c, hlt