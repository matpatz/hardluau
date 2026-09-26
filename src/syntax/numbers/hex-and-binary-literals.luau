-- hex-and-binary-literals.luau
-- Hexadecimal and binary integer literals, including case variants.

local h1 = 0xFF
local h2 = 0xff
local h3 = 0x10
local h4 = 0X0A
local h5 = 0xdeadBEEF
local b1 = 0b1010
local b2 = 0B1111
local b3 = 0b0
local b4 = 0b11111111111111111111111111111111
local mix = h1 + b1

assert(h1 == 255)
assert(h2 == 255)
assert(h3 == 16)
assert(h4 == 10)
assert(h5 == 3735928559)
assert(b1 == 10)
assert(b2 == 15)
assert(b3 == 0)
assert(b4 == 4294967295)
assert(mix == 265)
