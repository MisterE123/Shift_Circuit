-- Opt-in workaround for hosts where the system LuaJIT faults in native code.
-- This affects the server's main Lua state, not the client or mod security.
if core.settings:get_bool('shift_circuit_disable_jit',false) and jit and jit.off then
 jit.off()
 core.log('action','[Shift Circuit] LuaJIT compilation disabled by server configuration')
end
local path=core.get_modpath('shift_circuit')
if core.register_async_dofile then core.register_async_dofile(path..'/async_worker.lua')end
dofile(path..'/online.lua')
