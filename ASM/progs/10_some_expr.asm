r, a, xor, R0, R0, R0
i, a, mov, R4 
di, 16
i, a, mov, R5
di, 2
i, a, mov, R6
di, 256
r, a, shl, R2, R5
r, a, shr, R3, R4
r, a, add, R3, R2, R3
r, a, mul, R2, R2, R3
i, a, sub, R1, R2
di, 39
r, a, mov, R0, R1, R1 
r, c, hlt
r, c, hlt
r, c, hlt