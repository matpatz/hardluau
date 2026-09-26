-- metamethod-chains.luau
-- Arithmetic and comparison metamethods chained across operators.

local mt = {
    __add = function(a, b) return { value = a.value + b.value } end,
    __sub = function(a, b) return { value = a.value - b.value } end,
    __mul = function(a, b) return { value = a.value * b.value } end,
    __eq = function(a, b) return a.value == b.value end,
    __lt = function(a, b) return a.value < b.value end,
    __concat = function(a, b) return { value = a.value .. tostring(b) } end,
    __unm = function(a) return { value = -a.value } end,
    __len = function(a) return a.value end,
    __tostring = function(a) return "v=" .. a.value end,
}

local function num(n) return setmetatable({ value = n }, mt) end

local a, b, c = num(1), num(2), num(3)
local r1 = a + b * c
local r2 = -a
local r3 = a .. "!"
local r4 = #num(42)
local r5 = (a == num(1))
local r6 = (a < b)
local r7 = tostring(a)

assert(r1.value == 7)
assert(r2.value == -1)
assert(r3.value == "1!")
assert(r4 == 42)
assert(r5 == true)
assert(r6 == true)
assert(r7 == "v=1")
