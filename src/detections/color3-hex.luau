-- color3-hex.luau
-- Color3.fromRGB(255, 128, 0):ToHex() should produce "ff8000".

local Result = Color3.fromRGB(255, 128, 0):ToHex()

if Result == "ff8000" then
    print("yay")
else
    print("boo")
end
