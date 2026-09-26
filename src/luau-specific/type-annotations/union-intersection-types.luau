-- union-intersection-types.luau
-- Union (|) and intersection (&) type combinators.

type NumberOrString = number | string
type HasX = { x: number }
type HasY = { y: number }
type Both = HasX & HasY

local function describe(v: NumberOrString): string
    if typeof(v) == "number" then
        return "number"
    else
        return "string"
    end
end

local both: Both = { x = 1, y = 2 }

local function sumXY(p: Both): number
    return p.x + p.y
end

assert(describe(1) == "number")
assert(describe("s") == "string")
assert(sumXY(both) == 3)
