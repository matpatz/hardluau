-- unicode-in-strings.luau
-- UTF-8 multibyte sequences, combining marks, and astral-plane emoji.
-- Note: Luau has no \u{...} escape; code points must be literal UTF-8.

local smile = "😀"
local accented = "café résumé"
local cjk = "日本語のテキスト"
local rtl = "مرحبا بالعالم"
local combining = "é"          -- e + U+0301 combining acute accent

-- byte length vs character count surprises
local emojiLen = #smile       -- 4 (UTF-8 bytes), not 1

assert(smile == "😀")
assert(emojiLen == 4)
assert(accented == "café résumé")
assert(cjk == "日本語のテキスト")
assert(rtl == "مرحبا بالعالم")
assert(#combining == 3)
