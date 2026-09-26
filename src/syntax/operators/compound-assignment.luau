-- compound-assignment.luau
-- All Luau compound assignment operators, including on table fields
-- and in expressions with side effects.

local t = { 0, n = 1, s = "x" }
t.n += 1
t.n -= 2
t.n *= 3
t.n /= 4
t.n //= 5
t.n %= 6
t.n ^= 2
t.s ..= "y"

local i = 0
local function bump() i += 1 return i end

-- compound assignment evaluates the LHS expression exactly once
t[bump()] += 10   -- uses key 1

assert(t[1] == 10)
assert(t.n == 0)
assert(t.s == "xy")
assert(i == 1)
