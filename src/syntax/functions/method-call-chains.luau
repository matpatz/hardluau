-- method-call-chains.luau
-- Long method call chains using both : and . syntax.

local obj = {
    value = 0,
    add = function(self, n) self.value += n return self end,
    sub = function(self, n) self.value -= n return self end,
    get = function(self) return self.value end,
}

local r1 = obj:add(5):add(10):sub(3):get()          -- 12
local r2 = obj.add(obj, 1).add(obj, 1)              -- mixed . and :

local s = "hello world"
local r3 = s:upper():sub(1, 5):lower():rep(2)       -- "hellohello"

assert(r1 == 12)
assert(r2.value == 14)
assert(r3 == "hellohello")
