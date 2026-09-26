-- long-bracket-levels.luau
-- Long bracket strings with nested equal signs, and ] brackets inside.

local a = [[level 0]]
local b = [=[level 1 with ]] inside]=]
local c = [==[level 2 with ]=] and ]] inside]==]
local d = [==[
multi-line
level 2
]==]
local e = [[
first line
second line]]

-- a long bracket that starts with a newline immediately after the opener
local f = [[
]]

assert(a == "level 0")
assert(b == "level 1 with ]] inside")
assert(c == "level 2 with ]=] and ]] inside")
assert(d == "multi-line\nlevel 2\n")
assert(e == "first line\nsecond line")
assert(f == "")
