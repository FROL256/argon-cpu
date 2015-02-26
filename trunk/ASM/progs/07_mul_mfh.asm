r, 1, a, xor, R0, R0, R0
r, 1, a, xor, R1, R1, R1
r, 1, a, xor, R2, R2, R2
i, 1, a, mov, R4 
dh, 0x79af5120
i, 1, a, mov, R5
dh, 0x4ffffffe
r, 1, a, mul, R0, R4, R5, s
r, 1, a, mfh, R1, R0, R0
r, 1, a, mov, R2, R1, R1 
r, 0, c, hlt
r, 0, c, hlt
r, 0, c, hlt