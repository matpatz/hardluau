-- metatable-abuse.luau
-- Metatables that redefine core semantics in surprising ways.

local t = setmetatable({}, {
    __index = function(self, key)
        return "you asked for " .. tostring(key)
    end,
})

local a = t.anything
local b = t[123]

local counter = setmetatable({ n = 0 }, {
    __newindex = function(self, key, value)
        self.n += 1
        rawset(self, key, value)
    end,
})
counter.x = 1
counter.y = 2

local protected = setmetatable({}, {
    __metatable = "locked",   -- getmetatable now returns this string
})

assert(a == "you asked for anything")
assert(b == "you asked for 123")
assert(counter.n == 2)
assert(getmetatable(protected) == "locked")
