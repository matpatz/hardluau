-- check-task.luau
-- Detects runtimes with the `task` library: re-enters via task.spawn and
-- checks that the original coroutine is reported as a "normal" thread.

local thread = ...

if not thread then
    task.spawn(debug.info(1, "f"), coroutine.running())
    return
end

assert(type(thread) == "thread" and coroutine.status(thread) == "normal", "dtc")

print("hooray")
