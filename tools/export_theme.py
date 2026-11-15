from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1];target=root/'mods/shift_circuit/textures'
for source in (root/'art/ui').glob('*.png'):
 im=Image.open(source);scale=1 if source.stem.startswith(('sc_tile_','sc_fx_','sc_edge_','sc_pit_edge','sc_start_marker','sc_map_'))else 2
 im.resize((im.width*scale,im.height*scale),Image.Resampling.NEAREST).save(target/source.name)
print('Exported hand-edited UI sources without regenerating them.')

