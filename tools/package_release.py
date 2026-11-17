"""Build a clean source-inclusive ContentDB release archive."""
from pathlib import Path
import zipfile
root=Path(__file__).resolve().parents[1]
out=root.parent/'shift_circuit-contentdb.zip'
excluded={'.git','__pycache__','.pytest_cache','.venv','worlds','.idea','.vscode'}
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted(root.rglob('*')):
  rel=p.relative_to(root)
  if not p.is_file() or any(part in excluded for part in rel.parts):continue
  if p.name.startswith('.env') or p.suffix in {'.pyc','.log','.zip'}:continue
  z.write(p,Path('shift_circuit')/rel)
print(out.name, out.stat().st_size, 'bytes')
