r, 1, a, xor, R0, R0, R0
r, 1, a, xor, R2, R2, R2
i, 1, a, or,  R3, R0, R0 
dh, 0xfffffffe
i, 1, a, or,  R4, R0, R0
dh, 0xfffffffd
r, 1, a, add, R1, R3, R4
r, 1, a, adc, R0, R0, R0
r, 0, c, hlt
r, 0, c, hlt
r, 0, c, hlt