"""Run the real runtime against an engine contract stub; no desktop input."""
from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().modpath=str(root/'mods/shift_circuit').replace('\\','/')
lua.execute(r'''
function copy(t) if type(t)~='table' then return t end local r={};for k,v in pairs(t) do r[k]=copy(v) end;return r end
function same(a,b) if type(a)~=type(b) then return false end;if type(a)~='table' then return a==b end;for k,v in pairs(a) do if not same(v,b[k]) then return false end end;for k in pairs(b) do if a[k]==nil then return false end end;return true end
vector={new=copy,add=function(a,b) return {x=a.x+b.x,y=a.y+b.y,z=a.z+b.z} end,subtract=function(a,b) return {x=a.x-b.x,y=a.y-b.y,z=a.z-b.z} end,multiply=function(a,n) return {x=a.x*n,y=a.y*n,z=a.z*n} end}
local meta={};function meta:set_int(k,v) self[k]=v end;function meta:get_int(k) return self[k] or 0 end;function meta:set_string(k,v) self[k]=v end;function meta:get_string(k) return self[k] or '' end
function ItemStack(name) return {name=name,m=setmetatable({},{__index=meta}),get_meta=function(self) return self.m end} end
sounds={};objects={};callbacks={};tools={};clients={};nodes={};pending={};local storage={}
core={sound_play=function(n,p) sounds[#sounds+1]={name=n,params=copy(p)} end,get_modpath=function()return modpath end,get_mod_storage=function()return setmetatable(storage,{__index=meta})end,register_node=function(n,d)nodes[n]=d end,register_tool=function(n,d)tools[n]=d end,register_entity=function(n,d)callbacks.entity=d end,
 serialize=copy,deserialize=copy,formspec_escape=function(s)return s end,set_node=function()end,set_timeofday=function()end,add_particlespawner=function()end,
 get_player_privs=function()return {}end,set_player_privs=function()end,register_chatcommand=function()end,close_formspec=function()end,show_formspec=function(n,_,f)clients[n].shown=f end,
 raycast=function()return function()return nil end end,
 after=function(_,f)pending[#pending+1]=f end,emerge_area=function(a,b,f)f(nil,nil,0)end,get_player_by_name=function(n)return clients[n]end}
for _,name in ipairs({'on_joinplayer','on_leaveplayer','on_player_receive_fields','on_mods_loaded','globalstep','on_shutdown','allow_player_inventory_action'}) do core['register_'..name]=function(f)callbacks[name]=f end end
function core.add_entity(p)
 local o={p=copy(p),yaw=0,props={}};o.e={object=o}
 function o:get_luaentity()return self.e end
 function o:set_properties(t)for k,v in pairs(t)do self.props[k]=copy(v)end end
 function o:get_pos()return self.p and copy(self.p)end
 function o:set_pos(p)self.p=copy(p)end
 function o:move_to(p)self.p=copy(p)end
 function o:remove()self.p=nil end
 function o:set_yaw(a)self.yaw=a end
 function o:get_yaw()return self.yaw end
 objects[#objects+1]=o;return o
end
function newplayer(name)
 local p={name=name,p={x=2,y=3,z=4},yaw=.2,pitch=.3,fov=65,controls={},hud={},wield=1,teleports=0}
 p.inv={};function p.inv:set_size(_,n)self.size=n end;function p.inv:set_list(_,a)self.list=a end
 function p:get_inventory()return self.inv end
 function p:get_player_name()return self.name end
 function p:get_player_control()return self.controls end
 function p:get_properties()return {eye_height=1.625}end
 function p:get_look_dir()return {x=0,y=0,z=1}end
 function p:get_pos()return copy(self.p)end
 function p:set_pos(v)self.p=copy(v);self.teleports=self.teleports+1 end
 function p:get_look_horizontal()return self.yaw end;function p:set_look_horizontal(a)self.yaw=a end
 function p:get_look_vertical()return self.pitch end;function p:set_look_vertical(a)self.pitch=a end
 function p:get_fov()return self.fov end;function p:set_fov(f)self.fov=f end
 function p:set_attach(o)self.attached=o end;function p:set_detach()self.attached=nil end
 function p:get_wield_index()return self.wield end
 function p:hud_add(d)self.hud[#self.hud+1]=copy(d);return #self.hud end
 function p:hud_change(id,k,v)self.hud[id][k]=copy(v)end
 function p:hud_set_hotbar_itemcount(n)self.hotbar=n end
 function p:set_inventory_formspec(s)self.form=s end
 for _,n in ipairs({'set_physics_override','set_properties','set_sky','set_sun','set_moon','set_stars','hud_set_flags','hud_set_hotbar_image','hud_set_hotbar_selected_image'})do p[n]=function()end end
 clients[name]=p;callbacks.on_joinplayer(p);return p
end
function flush()while #pending>0 do local q=pending;pending={};for _,f in ipairs(q)do f()end end end
function tick(dt)callbacks.globalstep(dt);for _,o in ipairs(objects)do if o.p then callbacks.entity.on_step(o.e,dt)end end end
ui_events={};shift_circuit=dofile(modpath..'/runtime.lua')(core,{ui=function(n,pitch)ui_events[#ui_events+1]={name=n,pitch=pitch}end});callbacks.on_mods_loaded();flush()
local a=newplayer('Alpha');local b=newplayer('Beta');flush()
assert(a.shown and a.shown:find('START CAMPAIGN'),'welcome menu has an explicit start button')
assert(shift_circuit.start('Alpha','race',1))
local baseline=shift_circuit.snapshot().state
for i=1,100 do tick(.1)end
assert(same(baseline,shift_circuit.snapshot().state),'inspection mutated gameplay state')
local beams=0;local slat
for _,o in ipairs(objects)do if o.p then if o.props.mesh=='sc_beam.obj' and o.props.glow==7 then beams=beams+1 end;if o.e.belt and o.e.speed==1 then slat=o end end end
assert(beams==6,'fixed laser previews remain; ghost robot previews are hidden')
local previous=slat.e.travel;tick(.1);assert(math.abs((slat.e.travel-previous)%1-.1/.85*.5)<.0001,'half-speed conveyor preview')
assert(a.inv.list[1].name=='shift_circuit:commit' and a.hotbar==10,'visible commit plus nine cards')
assert(a.form:find('POWER') and a.form:find('LOADED WEAPON') and a.form:find('EQUIPMENT') and not a.form:find('textarea%['),'inventory integrates status, one weapon and equipment')
local gauges=0;for _,h in ipairs(a.hud)do if h.type=='image' and h.text:find('sc_stat_')then gauges=gauges+1 end;if h.type=='text'then assert(not h.text:find('ENERGY ') and not h.text:find('SHIELD '),'text stat HUD remains')end end
assert(gauges==7,'visual HUD gauges')
tools['shift_circuit:commit'].on_use(a.inv.list[1],a);assert(shift_circuit.snapshot().phase=='program','reject incomplete commit')
for _,p in ipairs({a,b})do for i=1,5 do local stack=p.inv.list[i+1];tools[stack.name].on_use(stack,p)end end
assert(a.inv.list[1].m.inventory_image=='sc_commit_ready.png','gold commit tool when ready')
a.controls.aux1=true;tick(.1);a.controls.aux1=false;assert(shift_circuit.snapshot().phase=='program','E must not commit')
local savedA={pos=copy(a.p),yaw=a.yaw,pitch=a.pitch};local savedB={pos={x=4,y=9,z=-2},yaw=1.2,pitch=.4};b:set_pos(savedB.pos);b:set_look_horizontal(savedB.yaw);b:set_look_vertical(savedB.pitch)
tools['shift_circuit:commit'].on_use(a.inv.list[1],a);assert(shift_circuit.snapshot().phase=='program','wait for other pilot');assert(a.inv.list[1].m.inventory_image=='sc_commit_locked.png','locked commit tool')
tools['shift_circuit:commit'].on_use(b.inv.list[1],b);assert(shift_circuit.snapshot().phase=='reading','explicit read phase')
assert(a.attached and b.attached and a.attached~=b.attached,'each pilot follows own robot')
local initial=shift_circuit.snapshot().state;tick(.3);assert(same(initial,shift_circuit.snapshot().state),'reading should precede execution')
local large=false;for _,h in ipairs(a.hud)do if h.type=='image' and h.scale and h.scale.x==1 and h.offset and h.offset.y>30 and h.text:find('sc_card_')then large=true end end;assert(large,'pixel-aligned card read animation')
local c=newplayer('Charlie');local savedC=copy(c.p);flush();assert(c.attached,'late observer also follows a robot')
local tp=a.teleports;for i=1,900 do tick(.1);if shift_circuit.snapshot().state.round==2 then break end end
assert(shift_circuit.snapshot().state.round==2,'full slowed round completed')
assert(not a.attached and not b.attached,'camera detached')
for _,p in ipairs({a,b})do local robot;for _,r in ipairs(shift_circuit.snapshot().state.bots)do if r.id==p.name then robot=r end end
 assert(p.p.x==robot.x*2+.5 and p.p.z==robot.z*2+.5 and p.p.y==7 and p.pitch==math.pi/2,'round return is above own robot')end
assert(not c.attached and same(c.p,savedC),'late observer view restored')
assert(a.teleports==tp+1,'only return teleport during execution')
assert(#shift_circuit.snapshot().state.bots[1].hand>=5,'redeal')
assert(shift_circuit.start('Alpha','race',1))
shift_circuit.queue('Alpha',1);shift_circuit.queue('Alpha',2)
local before=shift_circuit.snapshot().state.bots[1]
for i=1,500 do tick(.1)end
local warned=false;for _,h in ipairs(a.hud) do if h.type=='text' and h.text:find('Empty slots will be filled randomly')then warned=true end end
assert(warned and shift_circuit.snapshot().phase=='program','countdown warns before filling')
for i=1,100 do tick(.1)end
assert(shift_circuit.snapshot().phase=='reading','deadline starts execution')
for _,robot in ipairs(shift_circuit.snapshot().state.bots)do
 assert(#robot.program==5 and robot.ready,'deadline completes and commits each program')
 local seen={};for j,k in ipairs(robot.selected)do assert(not seen[k] and robot.program[j]==robot.hand[k],'random cards must come from unused hand');seen[k]=true end
 if robot.id==before.id then assert(robot.selected[1]==before.selected[1] and robot.selected[2]==before.selected[2],'preserves chosen order') end
end
callbacks.on_leaveplayer(b);clients.Beta=nil;callbacks.on_leaveplayer(c);clients.Charlie=nil
assert(shift_circuit.start('Alpha','race',1));for i=1,650 do tick(.1)end
assert(shift_circuit.snapshot().phase=='program' and not shift_circuit.snapshot().planning_left,'solo has no deadline')
print('PASS multiplayer deadline, warning, legal random fill, preserved choices, automatic commit, solo untimed')
print('PASS runtime: visual gauges, dashboard, commit, preview isolation, multiplayer readiness, card reading, individual follow cameras, return above robot, full round')
''')
# Validate image assets referenced by the actual instantiated HUD and inventory.
textures=root/'mods/shift_circuit/textures'
for _,p in lua.globals().clients.items():
    for _,h in p.hud.items():
        if h['type']=='image':
            for texture in h['text'].split('^'):
                assert (textures/texture).exists(),texture
    for _,stack in p.inv.list.items():
        texture=stack.m['inventory_image']
        if texture: assert (textures/texture.split('^')[0]).exists(),texture
print('PASS HUD and tool texture references')

lua.execute("""
local o=core.add_entity({x=0,y=1,z=0});o.e.robot=true;o.e.motion={from={x=0,y=1,z=0},to={x=2,y=1,z=0},elapsed=0,total=1.2}
callbacks.entity.on_step(o.e,.3);assert(o.p.x>.2 and o.p.x<.4,'robot remains visibly in transit after 300ms')
callbacks.entity.on_step(o.e,.9);assert(o.p.x==2 and not o.e.motion,'robot reaches exact destination')
print('PASS slow smooth robot travel and exact endpoint')
""")

lua.execute("""
local o=core.add_entity({x=0,y=1.4,z=0});o.e.collecting={origin=o:get_pos()}
callbacks.entity.on_step(o.e,.2);assert(o.p.y>1.4 and o.props.visual_size.x<1,'pickup rises and shrinks')
assert(sounds[#sounds].name=='sc_pickup','collection sound event')
callbacks.entity.on_step(o.e,.5);assert(not o.p,'collected item removed after animation')
for _,s in ipairs(sounds)do assert(s.params.gain>0 and s.params.max_hear_distance==35)end
print('PASS collection animation lifecycle and positional sound events')
""")

lua.execute("""
local click,commit,reject=false,false,false
for _,e in ipairs(ui_events)do click=click or e.pitch==1;commit=commit or e.pitch==1.25;reject=reject or e.pitch==.65 end
assert(click and commit and reject,'card selection, commit and rejection have distinct sound cues')
print('PASS program card sound hooks')
""")

