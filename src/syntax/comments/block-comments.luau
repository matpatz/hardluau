-- block-comments.luau
-- A block comment holding arbitrary text, then code with an inline comment.

--[[
a block comment
]]

local l = debug.info(1, "l")
print(l == 5) -- true
