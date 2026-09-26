-- mixed-key-styles.luau
-- Array, named, and mixed keys in a single constructor,
-- including keys that are keywords, strings, and expressions.

local t = {
    1, 2, 3,                    -- array part
    name = "value",             -- named key (identifier)
    ["spaced key"] = 1,         -- string key
    ["while"] = 2,              -- keyword as key
    [true] = "bool",            -- boolean key
    [1 + 1] = "computed",       -- expression key
    ["mixed"] = { nested = true },
    last                        -- trailing array item, no trailing comma
}

assert(t[1] == 1)
assert(t[2] == "computed")
assert(t[3] == 3)
assert(t.name == "value")
assert(t["spaced key"] == 1)
assert(t["while"] == 2)
assert(t[true] == "bool")
assert(t.mixed.nested == true)
