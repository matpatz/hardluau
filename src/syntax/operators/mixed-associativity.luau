-- mixed-associativity.luau
-- Mixes left- and right-associative operators in a single expression.
-- Verifies associativity handling, not just precedence.

local x = 10 - 3 - 2           -- left: (10-3)-2 = 5
local y = 2 ^ 3 ^ 2            -- right: 2^(3^2) = 512
local z = "a" .. "b" .. "c"    -- right-associative concat: "a"..("b".."c")
local w = 100 // 10 // 5       -- left: (100//10)//5 = 2
local u = 1 - (2 - (3 - 4))    -- explicit nesting flips everything
local v = (1 .. 2) .. (3 .. 4)

assert(x == 5)
assert(y == 512)
assert(z == "abc")
assert(w == 2)
assert(u == -2)
assert(v == "1234")
