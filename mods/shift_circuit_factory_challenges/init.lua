local modname = core.get_current_modname()
local ok, err = shift_circuit.register_board_pack(modname, 'boards.json')
if not ok then error(err) end
ok, err = shift_circuit.register_puzzle_pack(modname, 'puzzles.json')
if not ok then error(err) end
