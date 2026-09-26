-- coercion-edge-cases.luau
-- Implicit string-to-number coercions and comparison edge cases.

local a = "10" + 5            -- 15
local b = "10" .. 5           -- "105"
local c = " 5 " + 0           -- 5 (whitespace tolerated)
local d = "10.5" + 0.5        -- 11
local e = "-3" + 0            -- -3

local f = (nil == false)      -- false
local g = (0 == "0")          -- false (no cross-type coercion in ==)
local h = (true == 1)         -- false
local i = #"abc"              -- 3

-- These would raise at runtime and are deliberately NOT executed:
-- local bad1 = "abc" + 1
-- local bad2 = 1 < "2"

assert(a == 15)
assert(b == "105")
assert(c == 5)
assert(d == 11)
assert(e == -3)
assert(f == false)
assert(g == false)
assert(h == false)
assert(i == 3)
