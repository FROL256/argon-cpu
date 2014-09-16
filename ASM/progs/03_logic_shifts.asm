r, 1, a, xor, R0, R0, R0
r, 1, a, xor, R1, R1, R1
r, 1, a, xor, R2, R2, R2
i, 1, a, mov, R3
di, 1
i, 1, a, mov, R4
dh, 0xFFFFFFFE
r, 1, a, shl, R0, R3
r, 1, a, shr, R1, R4, R0, s
r, 0, a, nop
r, 0, c, hlt
r, 0, c, hlt
r, 0, c, hlt