-- deprecated-attribute.luau
-- @deprecated attribute marks an API as deprecated; using it emits a warning.

--!nonstrict

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
