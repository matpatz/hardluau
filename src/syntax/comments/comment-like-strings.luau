-- comment-like-strings.luau
-- Strings that contain comment-looking content, and comments that
-- contain string-looking content.

local a = "-- not a comment"
local b = "--[[ not a block comment ]]"
local c = [==[
--[[ this is inside a string, not a comment ]]
-- still string
]==]
local d = "x" -- real comment with "quotes" and [[brackets]]

-- block comment containing an unclosed string:
-- local e = "unclosed
local f = "ok"

assert(a == "-- not a comment")
assert(b == "--[[ not a block comment ]]")
assert(c == "--[[ this is inside a string, not a comment ]]\n-- still string\n")
assert(d == "x")
assert(f == "ok")
