-- string-interpolation-nested.luau
-- Luau interpolated strings with nested braces and expressions.

local name = "world"
local greeting = `hello {name}`
local calc = `1 + 2 = {1 + 2}`
local nested = `outer {`inner {name}`} tail`
local brace = `literal \{ not an expr \}`

assert(greeting == "hello world")
assert(calc == "1 + 2 = 3")
assert(nested == "outer inner world tail")
assert(brace == "literal { not an expr }")
