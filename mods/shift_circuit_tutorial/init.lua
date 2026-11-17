local ok,err=shift_circuit.register_puzzle_pack(core.get_current_modname(), 'puzzles.json')
if not ok then error(err)end
