i, 1, a, mov, R2 
d, {3}
r, 0, m, sw,  0,  R1, R2, 255  // mem(R2+255) := R1
r, 1, m, lw,  R0, 0,  R2, 255  // R0 = mem(R2+255) 
r, 0, c, hlt, 0, 0, 0
r, 0, c, hlt, 0, 0, 0
r, 0, c, hlt, 0, 0, 0