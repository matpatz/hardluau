-- deeply-nested-blocks.luau
-- Many nested do/if/while blocks with shadowed locals.

local result = 0
do
    local x = 1
    do
        local x = 2
        do
            local x = 3
            do
                local x = 4
                if true then
                    if x > 0 then
                        while x > 0 do
                            x -= 1
                            result += 1
                            if x == 2 then
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end

assert(result == 2)
