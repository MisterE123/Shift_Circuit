from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r\'\'\'",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
setup=(root/'tests/test_online.py').read_text().split("lua.execute(\'\'\'",1)[1].split('local smallboard=',1)[0];lua.execute(setup)
lua.execute("""
dofile(modpath..'/online.lua');callbacks.on_mods_loaded();flush()
local joined=callbacks.on_joinplayer;callbacks.on_joinplayer=function(p)
 p.visuals={};p.flags={};p.set_properties=function(_,v)for k,x in pairs(v)do p.visuals[k]=x end end;p.hud_set_flags=function(_,v)for k,x in pairs(v)do p.flags[k]=x end end;joined(p)
end
local a=newplayer('PilotA');local b=newplayer('PilotB');flush()
local function hidden(p)assert(p.visuals.is_visible==false and p.visuals.pointable==false and p.visuals.nametag==''and p.visuals.nametag_color=='#00000000');assert(p.flags.wielditem==false,'no first-person hand')end
local function lobby(p)assert(p.visuals.is_visible==true and p.visuals.mesh=='sc_lobby_robot.obj'and p.visuals.nametag==p.name);assert(p.flags.wielditem==false and p.flags.hotbar==false,'lobby hides empty hotbar')end
lobby(a);lobby(b);local hint=false;for _,h in ipairs(a.hud)do if h.text=='Press I for main menu'then hint=true end end;assert(hint,'lobby offers the inventory menu key');assert(not same(a.p,b.p),'separate lobby spawn positions')
shift_circuit.new_room({'PilotA'},true,false,1,'tutorial');tick(.1);flush();tick(.1);hidden(a);assert(a.flags.hotbar==true,'robot control tools remain in hotbar')
shift_circuit.leave('PilotA');lobby(a);lobby(b)
print('PASS selected robot avatars and separate spawns in lobby, hidden pilot in matches, no hand, restored lobby appearance')
""")

models=root/'mods/shift_circuit/models'
for p in models.glob('sc_lobby_*.obj'):
 ys=[float(line.split()[2])for line in p.read_text().splitlines()if line.startswith('v ')]
 assert abs(min(ys))<1e-6, p.name
assert len(list(models.glob('sc_lobby_*.obj')))==16
print('PASS all sixteen lobby models are aligned to their feet')
