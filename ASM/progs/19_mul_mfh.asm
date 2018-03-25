r, a, xor, R0, R0, R0
r, a, xor, R1, R1, R1
r, a, xor, R2, R2, R2
i, a, mov, R4 
dh, 0x79af5120
i, a, mov, R5
dh, 0x4ffffffe
r, a, mul, R0, R4, R5, s
r, a, mfh, R1, R0, R0
r, a, mov, R2, R1, R1 
r, c, hlt
r, c, hlt
r, c, hlt