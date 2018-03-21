r, a, xor, R0, R0, R0
r, a, xor, R1, R1, R1
r, a, xor, R2, R2, R2
i, a, mov, R3
di, 1
i, a, mov, R4
dh, 0xFFFFFFFE
r, a, shl, R0, R3
r, a, shr, R1, R4, R0, s
r, a, nop
r, c, hlt
r, c, hlt
r, c, hlt