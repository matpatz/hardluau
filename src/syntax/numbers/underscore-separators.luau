-- underscore-separators.luau
-- NOTE: Luau does NOT support digit-grouping underscores in numerals.
-- A conforming parser must REJECT the commented lines below.
-- Kept in the corpus to catch parsers that silently accept them.

local valid = 1000000

-- The following are intentionally invalid in Luau:
-- local bad1 = 1_000_000
-- local bad2 = 0xDEAD_BEEF
-- local bad3 = 0b1010_1010
-- local bad4 = 1_2e3

assert(valid == 1000000)
