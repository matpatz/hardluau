-- unm-returns-operand.luau
-- A __unm metamethod that returns its operand (identity unary minus), then the
-- length operator on the string-key-only global environment evaluates to 0.

local function this()
    local a = getfenv()
    local index = getmetatable(a).__index

    setmetatable(a, {
        __index = index,
        __unm = function(f)
            return f
        end
    })

    return -a
end

assert(#this() == 0, "length of f should be 0")
