-- comments-inside-expressions.luau
-- Comments embedded inside expressions and across line breaks.

local function f(x, y) return x + y end

local a = 1 + -- comment after operator
    2

local b = {
    1, -- comment after item
    2,
    -- full-line comment inside constructor
    3,
}

local c = f(
    -- comment inside call args
    1,
    2 -- trailing comment
)

local d = a --[[ block ]] + #b

assert(a == 3)
assert(#b == 3)
assert(b[2] == 2)
assert(c == 3)
assert(d == 6)
