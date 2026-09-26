-- generic-functions.luau
-- Generic functions with type parameters and inferred/declared bounds.

local function id<T>(x: T): T
    return x
end

local function pair<A, B>(a: A, b: B): (A, B)
    return a, b
end

local function map<T, U>(t: {T}, f: (T) -> U): {U}
    local out = {}
    for _, v in t do
        table.insert(out, f(v))
    end
    return out
end

local a: number = id(1)
local b: string = id("s")
local c, d = pair(1, "two")
local e = map({1, 2, 3}, function(n) return tostring(n) end)

assert(a == 1)
assert(b == "s")
assert(c == 1)
assert(d == "two")
assert(e[2] == "2")
