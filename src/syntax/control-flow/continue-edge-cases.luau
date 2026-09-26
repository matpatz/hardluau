-- continue-edge-cases.luau
-- Luau continue statement in loops, including nested loops
-- where continue targets the nearest enclosing loop.

local total = 0
for i = 1, 10 do
    if i % 2 == 0 then
        continue
    end
    total += i
end

local found = false
for i = 1, 3 do
    for j = 1, 3 do
        if j == 2 then
            continue        -- continues the inner loop only
        end
        if i == 2 and j == 3 then
            found = true
            break
        end
    end
end

-- continue inside a while loop
local k = 0
local sum = 0
while k < 5 do
    k += 1
    if k == 3 then
        continue
    end
    sum += k
end

assert(total == 25)
assert(found == true)
assert(sum == 12)
