-- varargs-edge-cases.luau
-- vararg (...) edge cases: empty varargs, forwarding, and select counts.

local function count(...) return select("#", ...) end
local function forward(...) return ... end
local function packer(...) return table.pack(...) end

local n0 = count()                -- 0
local n3 = count(1, 2, 3)         -- 3
local a, b, c = forward(1, 2, 3)  -- 1, 2, 3
local e, f = forward(9)           -- 9, nil
local p = packer("x", "y")        -- {"x", "y"}

assert(n0 == 0)
assert(n3 == 3)
assert(a == 1 and b == 2 and c == 3)
assert(e == 9 and f == nil)
assert(p.n == 2)
assert(p[1] == "x" and p[2] == "y")
