-- shadowing-chains.luau
-- Chains of shadowed locals, including function params and loop vars.

local x = "global"
do
    local x = "outer"
    do
        local x = "inner"
        do
            local x = "deepest"
            -- here x is "deepest"
        end
    end
end

local function f(x)
    local x = x or "default"   -- param shadowed by local
    return x
end

local total = 0
for x = 1, 3 do
    local x = x * 10           -- loop var shadowed by local
    total += x
end

assert(x == "global")
assert(f(nil) == "default")
assert(f("arg") == "arg")
assert(total == 60)
