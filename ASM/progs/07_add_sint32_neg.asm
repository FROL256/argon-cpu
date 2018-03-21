r, a, xor, R0, R0, R0
r, a, xor, R2, R2, R2
i, a, or,  R3, R0, R0 
dh, 0xfffffffe
i, a, or,  R4, R0, R0
dh, 0xfffffffd
r, a, add, R1, R3, R4
r, a, adc, R0, R0, R0
r, c, hlt
r, c, hlt
r, c, hlt