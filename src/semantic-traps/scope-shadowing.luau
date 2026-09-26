-- scope-shadowing.luau
-- Locals shadowing globals, builtins, and each other at every scope.

local print = "shadowed print"   -- shadows the global builtin

do
    local print = 42
    local table = {}
    local string = "x"
    -- references are held but not called, so no runtime error here
end

local x = 1
do
    local x = x + 1   -- inner x shadows outer; reads outer x on the RHS
    assert(x == 2)
end
assert(x == 1)

local function f() return "outer" end
do
    local f = function() return "inner" end
    assert(f() == "inner")
end

assert(print == "shadowed print")
assert(x == 1)
assert(f() == "outer")
