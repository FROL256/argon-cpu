r, a, xor, R0, R0, R0
i, a, mov, R4 
di, 16
i, a, mov, R5
di, 2
i, a, mov, R6
dh, 0xFFFFFFFE
r, a, mul, R0, R4, R5, s
r, a, mul, R1, R4, R6, s
r, a, mov, R2, R4, R4 
r, c, hlt
r, c, hlt
r, c, hlt