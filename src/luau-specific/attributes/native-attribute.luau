-- native-attribute.luau
-- @native attribute on functions, marking them as native-code candidates.

--!native

@native
local function fastSum(a: number, b: number): number
    return a + b
end

local result = fastSum(1, 2)
assert(result == 3)
