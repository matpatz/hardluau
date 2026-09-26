-- scientific-notation.luau
-- Decimal exponent forms, including edge mantissa/exponent cases.

local e1 = 1e10
local e2 = 1E10
local e3 = 1.5e-3
local e4 = 1.5e+3
local e5 = .5e3        -- leading dot
local e6 = 5.e3        -- trailing dot before exponent
local e7 = 1e0
-- local e8 = 1e       -- invalid: exponent sign/digits required
-- local e9 = 1e+      -- invalid

local big = 1e308
local tiny = 1e-308

assert(e1 == 1e10)
assert(e2 == 1e10)
assert(e3 == 0.0015)
assert(e4 == 1500)
assert(e5 == 500)
assert(e6 == 5000)
assert(e7 == 1)
assert(big == 1e308)
assert(tiny == 1e-308)
