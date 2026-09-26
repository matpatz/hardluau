-- deprecated-attribute.luau
-- @deprecated marks an API as deprecated; the linter warns when it's called
-- (an analyzer lint, not a runtime error).

--!strict

@deprecated
local function oldApi()
    return "old"
end

local function newApi()
    return "new"
end

-- using the deprecated function here triggers a lint warning
local result = oldApi()
assert(result == "old")
assert(newApi() == "new")
