-- escape-sequences.luau
-- Every standard Luau string escape, plus edge placements.

local bell = "\a"
local backspace = "\b"
local formfeed = "\f"
local newline = "\n"
local cr = "\r"
local tab = "\t"
local vtab = "\v"
local backslash = "\\"
local quote = "\""
local single = '\''
local hex = "\x41\x42\x43"        -- "ABC"
local dec = "\065\066\067"        -- "ABC"
local trailing = "ends with backslash\\"
local nul = "\0"

-- escape at the very start and very end of a string
local edge1 = "\""
local edge2 = "\\"

assert(bell == "\a")
assert(backspace == "\b")
assert(formfeed == "\f")
assert(newline == "\n")
assert(cr == "\r")
assert(tab == "\t")
assert(vtab == "\v")
assert(backslash == "\\")
assert(quote == "\"")
assert(single == "'")
assert(hex == "ABC")
assert(dec == "ABC")
assert(trailing == "ends with backslash\\")
assert(nul == "\0")
assert(edge1 == "\"")
assert(edge2 == "\\")
