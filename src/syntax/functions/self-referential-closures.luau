-- self-referential-closures.luau
-- Closures that capture themselves or the function being defined.

local fact
fact = function(n)
    if n <= 1 then return 1 end
    return n * fact(n - 1)        -- captures fact
end

local function counter()
    local c = 0
    return function()
        c += 1
        return c
    end
end

local inc = counter()

local fib
fib = function(n)
    if n < 2 then return n end
    return fib(n - 1) + fib(n - 2)
end

assert(fact(5) == 120)
assert(fib(10) == 55)
local one = inc()
local two = inc()
assert(one == 1 and two == 2)
