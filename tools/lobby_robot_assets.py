from pathlib import Path
root=Path(__file__).resolve().parents[1];models=root/'mods/shift_circuit/models'
for p in models.glob('sc_robot*.obj'):
 lines=p.read_text().splitlines();bottom=min(float(line.split()[2])for line in lines if line.startswith('v '))
 out=[]
 for line in lines:
  if line.startswith('v '):
   fields=line.split();fields[2]=str(float(fields[2])-bottom);line=' '.join(fields)
  if line.startswith('mtllib '):line='mtllib sc_lobby_'+p.stem[3:]+'.mtl'
  out.append(line)
 (models/('sc_lobby_'+p.name[3:])).write_text('\n'.join(out)+'\n',newline='\n')
 (models/('sc_lobby_'+p.stem[3:]+'.mtl')).write_text(p.with_suffix('.mtl').read_text(),newline='\n')
