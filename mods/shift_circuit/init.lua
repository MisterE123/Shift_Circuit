local path=core.get_modpath('shift_circuit')
if core.register_async_dofile then core.register_async_dofile(path..'/async_worker.lua')end
dofile(path..'/online.lua')
