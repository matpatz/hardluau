-- type-aliases-recursive.luau
-- Recursive type aliases (tree, linked list) and a mutual reference.

type Tree = { value: number, children: {Tree} }
type List = { head: number, tail: List? }

local tree: Tree = {
    value = 1,
    children = {
        { value = 2, children = {} },
        { value = 3, children = {} },
    },
}

local list: List? = nil

-- mutual (forward) reference between two aliases
type B = { a: A? }
type A = { b: B? }

assert(tree.value == 1)
assert(tree.children[1].value == 2)
assert(tree.children[2].value == 3)
assert(list == nil)
