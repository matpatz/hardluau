-- trailing-commas-semicolons.luau
-- Trailing commas and semicolons in table constructors, plus empty slots.

local a = { 1, 2, 3, }
local b = { 1, 2, 3; 4, 5 }          -- semicolon separator
local c = { 1, 2, 3; }               -- trailing semicolon
local d = { }                        -- empty
local e = { [1] = "x", [2] = "y", }  -- trailing comma after named field
local f = { 1, 2, 3, 4, 5, }         -- all trailing comma

assert(#a == 3 and a[3] == 3)
assert(#b == 5 and b[5] == 5)
assert(#c == 3)
assert(#d == 0)
assert(e[1] == "x" and e[2] == "y")
assert(#f == 5)
