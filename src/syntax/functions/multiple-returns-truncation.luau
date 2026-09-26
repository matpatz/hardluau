-- multiple-returns-truncation.luau
-- Multiple return values truncate to one value in most expression
-- positions, but expand at the tail of calls and assignments.

local function three() return 1, 2, 3 end

local a = three()                 -- 1
local b, c, d = three()           -- 1, 2, 3
local e, f = three()              -- 1, 2 (truncated)
local g = { three() }             -- {1, 2, 3} (expands in constructor)
local h = { three(), 99 }         -- {1, 99} (truncated, not last)
local i = (three())               -- 1 (parenthesized -> single value)

local function pass(x, y, z) return x, y, z end
local j = pass(three())           -- pass(1,2,3)

assert(a == 1)
assert(b == 1 and c == 2 and d == 3)
assert(e == 1 and f == 2)
assert(g[3] == 3 and #g == 3)
assert(h[1] == 1 and h[2] == 99)
assert(i == 1)
assert(j == 1)
