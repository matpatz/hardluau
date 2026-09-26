-- long-bracket-call-sugar.luau
-- String call sugar: long-bracket strings and a block comment inside a function.

a,b=function(...)print(...)--[[return[]{}]]end;b=a
if(a('Hi'))then b[[or(true)[]] end
if(a"!")then end
