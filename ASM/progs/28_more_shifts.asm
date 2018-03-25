r, a, xor, R0, R0, R0
r, a, xor, R1, R1, R1
r, a, xor, R2, R2, R2
i, a, mov, R3
di, 2
i, a, mov, R4
di, 512
i, a, mov, R5
dh, 0xfffffffe
i, a, mov, R6
dh, 0xfffffe00
i, a, mov, R7
di, 2
i, a, mov, R8
di, 3
r, a, shl, R0, R3, R7
r, a, shr, R1, R4, R8
r, a, add, R0, R0, R1
r, a, shl, R1, R5, R7, s
r, a, shr, R2, R6, R8, s
r, c, hlt
r, c, hlt
r, c, hlt