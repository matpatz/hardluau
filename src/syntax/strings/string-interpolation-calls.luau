-- string-interpolation-calls.luau
-- Function calls inside interpolated strings: zero-arg, multi-arg, nested.

local function k(a, b)
    return a + b
end

local function greet()
    return "hello"
end

assert(`{k(1, 2)}` == "3")
assert(`{greet()}` == "hello")
assert(`{k(k(1, 2), k(3, 4))}` == "10")
