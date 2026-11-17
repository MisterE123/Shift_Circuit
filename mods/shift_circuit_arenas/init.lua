local ok,err=shift_circuit.register_board_pack(core.get_current_modname(), 'boards.json')
if not ok then error(err)end
