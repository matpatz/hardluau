-- ambiguous-call-syntax.luau
-- Call syntax variants that parsers commonly confuse.

local function f(...) return ... end

local a = f "string arg"          -- sugar: f("string arg")
local b = f { 1, 2, 3 }           -- sugar: f({1,2,3})
local c = f("normal")
local d = f("x"):upper()          -- method call on call result
local e = f { x = 1, y = 2 }      -- table sugar with named fields
local g = ("x"):upper()           -- method call on parenthesized literal

-- function calls nested directly in another call's arguments
local h = f(f(f(1)))

assert(a == "string arg")
assert(b[2] == 2)
assert(c == "normal")
assert(d == "X")
assert(e.x == 1 and e.y == 2)
assert(g == "X")
assert(h == 1)
