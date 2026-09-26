-- precedence-chains.luau
-- Stress-tests operator precedence across long mixed chains.

local a = 1 + 2 * 3 ^ 2        -- 1 + 2*9 = 19
local b = 1 .. 2 .. 3 .. 4     -- "1234"
local c = not not not true     -- false
local d = - - - 5              -- -5
local e = #"abc" + #"de" * 2   -- 3 + 2*2 = 7
local f = 2 ^ 3 ^ 2            -- right-associative: 2^(3^2) = 512
local g = (2 ^ 3) ^ 2          -- 64
local h = 10 - 3 - 2           -- left-associative: 5
local i = 100 // 10 // 5       -- floor division, left-associative: 2
local j = 2 < 3 == true        -- (2 < 3) == true -> true

assert(a == 19)
assert(b == "1234")
assert(c == false)
assert(d == -5)
assert(e == 7)
assert(f == 512)
assert(g == 64)
assert(h == 5)
assert(i == 2)
assert(j == true)
