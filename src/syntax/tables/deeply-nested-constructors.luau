-- deeply-nested-constructors.luau
-- Table constructors nested many levels deep.

local deep = {
    a = {
        b = {
            c = {
                d = {
                    e = {
                        f = { 1, 2, 3, { "leaf" } }
                    }
                }
            }
        }
    }
}

local arr = { { { { { { { { { { 1 } } } } } } } } } }

assert(deep.a.b.c.d.e.f[1] == 1)
assert(deep.a.b.c.d.e.f[4][1] == "leaf")
assert(arr[1][1][1][1][1][1][1][1][1][1] == 1)
