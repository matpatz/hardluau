-- nested-interpolation.luau
-- Interpolated strings with nested interpolation expressions and braces.

local name = "world"
local items = { "a", "b", "c" }

local function pick(n)
    if n == "world" then return "yes" end
    return "no"
end

local s1 = `hello {name}!`
local s2 = `{`inner {name}`}`
local s3 = `count = {#items}`
local s4 = `\{literal braces\}`
local s5 = `join: {table.concat(items, ",")}`
local s6 = `{pick(name)}`

assert(s1 == "hello world!")
assert(s2 == "inner world")
assert(s3 == "count = 3")
assert(s4 == "{literal braces}")
assert(s5 == "join: a,b,c")
assert(s6 == "yes")
