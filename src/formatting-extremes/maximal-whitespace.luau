-- maximal-whitespace.luau
-- Excessively padded program: tabs, spaces, and blank lines everywhere.

local   a    =    1


local   function   f   (   x   )

    return   x   *   2

end


local   t   =   {
    1   ,
    2   ,
    3   ,
}


local   s   =   "hi"   ..   "!"


return   a   ,   f   (   a   )   ,   t   ,   s
