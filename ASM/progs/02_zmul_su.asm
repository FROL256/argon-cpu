r, 1, a, xor, R0, R0, R0
i, 1, a, mov, R4 
di, 16
i, 1, a, mov, R5
di, 2
i, 1, a, mov, R6
dh, 0xFFFFFFFE
r, 1, a, mul, R0, R4, R5, s
r, 1, a, mul, R1, R4, R6, s
r, 1, a, mov, R2, R4, R4 
r, 0, c, hlt
r, 0, c, hlt
r, 0, c, hlt