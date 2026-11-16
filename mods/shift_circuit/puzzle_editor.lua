-- Puzzle settings share the Workshop draft and its autosave/undo lifecycle.
return function(core,L,draft,save,draw,back)
 local MenuUI=dofile(core.get_modpath('shift_circuit')..'/menu_ui.lua');core=MenuUI.wrap(core)
 local U={};local views={};local esc=core.formspec_escape
 local Cards=dofile(core.get_modpath('shift_circuit')..'/card_text.lua')
 local cards={'STEP','DASH','MOVE3','BACK','BACK2','LEFT','RIGHT','UTURN','WAIT'}
 local items={'reset_button','electromagnetic_brake','battering_ram','mechanical_arm','turret_gearbox','thermal_camera','blink','range','cache','hard_disk','gyro_stabilizer','electroshield','titanium_hull','holographic_memory','blueprint_archive'}
 local weapons={'green_laser','double_laser','triple_laser','emp_generator','remote_control','tractor_beam','repulsor_beam'}
 local function config(n)local d=draft(n).data;d.puzzle=d.puzzle or {checkpoints={},targets={},hands={},equipment={},hull=5,power=4,weapon='green_laser',limit=0,order=1};return d,d.puzzle end
 function U.open(n)
  local d,p=config(n);local v=views[n]or {tab=1,mode='start',round=1};views[n]=v
  local f={'formspec_version[6]size[16,12]background[0,0;16,12;sc_setup_background.png]style_type[button;bgimg=sc_menu_button.png;bgimg_pressed=sc_menu_button_pressed.png;border=false]label[.6,.5;PUZZLE / '..esc(d.title)..']'}
  local function add(s)f[#f+1]=s end
  for i,t in ipairs({'OBJECTIVES','ROBOT','CARDS','DETAILS'})do add(('button[%s,1.1;3.5,.65;tab_%d;%s%s]'):format(.6+(i-1)*3.8,i,v.tab==i and '> 'or '',t))end
  if v.tab==1 then
   local cell=7.2/d.size
   for z=1,d.size do for x=1,d.size do local key=x..','..z;local t=d.board[key];local label='';local color='#263d49'
    if t.kind=='pit'or (t.kind=='trapdoor'and t.open)then color='#080f16'elseif t.kind=='checkpoint'then label='?';color='#38796f'end
    if (d.crates or {})[key]then label='C';color='#997633'end;if (d.enemies or {})[key]then label='E';color='#8e493d'end
    for i,k in ipairs(p.checkpoints)do if k==key then label=tostring(i);color='#379d89'end end
    for _,id in ipairs(p.targets)do if id:sub(id:find(':')+1)==key then label='X';color='#be5940'end end
    if d.start.x==x and d.start.z==z then label='S';color='#527aaa'end
    local icon='sc_tile_deck.png'
    if t.kind=='belt'then icon='sc_map_'..(t.entry and 'bend_'..((t.dir-t.entry)%4==1 and 'right_'or 'left_')or 'belt_')..(t.speed or 1)..'_'..(t.dir or 0)..'.png'
    elseif t.kind=='checkpoint'then icon='sc_map_checkpoint.png'elseif t.kind=='pit'or t.kind=='repair'then icon='sc_map_'..t.kind..'.png'
    elseif t.kind=='factory'then icon='sc_map_factory_'..t.pattern..'_'..t.dir..'.png'
    elseif t.kind=='rotator'then icon='sc_map_rotator_'..t.turn..'.png'elseif t.kind=='plate'then icon='sc_map_plate.png'elseif t.kind=='trapdoor'then icon='sc_map_trap_'..(t.open and 'open'or 'closed')..'.png'end
    if (d.crates or {})[key]then icon='sc_map_crate_'..d.crates[key].kind..'.png'end;if (d.enemies or {})[key]then icon='sc_map_enemy_'..d.enemies[key].kind..'.png'end
    if label=='S'or label=='X'or tonumber(label)then icon=icon..'^[colorize:'..color..':100'end
    add(('image_button[%s,%s;%s,%s;%s;at_%d_%d;%s]'):format(.6+(x-1)*cell,2+(d.size-z)*cell,cell,cell,esc(icon),x,z,label))
   end end
   add('label[8.2,2.2;CLICK THE BOARD TO SELECT]')
   for i,t in ipairs({'start','checkpoint','target'})do add(('button[8.2,%s;7,.7;mode_%s;%s%s]'):format(2.7+(i-1)*.9,t,v.mode==t and '> 'or '',t:upper()))end
   add('textarea[8.2,5.6;7,2.1;;;S = start / ? = checkpoint candidate\nC = crate / E = enemy / X = target\nClick a selected checkpoint or target to remove it.]')
   add('button[8.2,8;7,.7;clear_objectives;CLEAR OBJECTIVES]label[8.2,9.1;'..#p.checkpoints..' checkpoints / '..#p.targets..' targets]')
  elseif v.tab==2 then
   add(('field[.7,2.5;3,.7;hull;Starting hull;%d]field[4,2.5;3,.7;power;Starting power;%d]'):format(p.hull,p.power))
   local wi=1;local labels={};for i,k in ipairs(weapons)do labels[i]=k:gsub('_',' ');if k==p.weapon then wi=i end end
   add('label[8,2.1;WEAPON]dropdown[8,2.5;7,.7;weapon;'..table.concat(labels,',')..';'..wi..';true]')
   for i,k in ipairs(items)do local x=i<=7 and .7 or 8;local y=3.6+((i-1)%7)*.75;local count=p.equipment[k]or 0
    add(('label[%s,%s;%s]button[%s,%s;.6,.55;less_%s;-]label[%s,%s;%d]button[%s,%s;.6,.55;more_%s;+]'):format(x,y+.28,k:gsub('_',' '),x+4.6,y,k,x+5.4,y+.28,count,x+6,y,k))
   end
   add('label[.7,9.5;START FACING]dropdown[3,9.2;4,.65;start_facing;North,East,South,West;'..(d.start.dir+1)..';true]label[8,9.5;Fresh loadout on every attempt.]')
  elseif v.tab==3 then
   add('field[.7,2.5;2,.7;round;Round;'..v.round..']button[2.9,2.5;2,.7;show_round;SHOW]button[5.2,2.5;4,.7;random_hand;USE RANDOM HAND]')
   add('label[.7,3.6;Click cards to add them. Click a dealt card below to remove it.]')
   for i,k in ipairs(cards)do add(('image_button[%s,4.1;1.3,1.3;sc_cmd_%s.png;card_%s;]tooltip[card_%s;%s]'):format(.7+(i-1)*1.65,k,k,k,esc(Cards.tooltip(k))))end
   local hand=p.hands[tostring(v.round)];add('label[.7,6;'..(hand and ('EXPLICIT HAND / '..#hand..' OF 12 CARDS')or 'RANDOM HAND / Normal draw rules')..']')
   for i,k in ipairs(hand or {})do add(('image_button[%s,%s;1,1;sc_cmd_%s.png;remove_%d;]tooltip[remove_%d;%s]'):format(.7+((i-1)%8)*1.7,6.6+math.floor((i-1)/8)*1.4,k,i,i,esc(Cards.tooltip(k))))end
   add('label[.7,9.8;Explicit hands require 5-12 cards. Other rounds use random draws.]')
  else
   add('textarea[.7,2.4;14.5,1.8;description;Description;'..esc(p.description or '')..']')
   add('textarea[.7,4.6;14.5,1.8;hint;HUD hint (optional - 180 characters);'..esc(p.hint or '')..']')
   add('field[.7,7;4,.7;limit;Round limit (0 = unlimited);'..p.limit..']field[5.1,7;4,.7;order;Pack order;'..(p.order or 1)..']')
   add('checkbox[.7,8.2;no_reboot;Fail when your robot is destroyed;'..tostring(p.no_reboot==true)..']')
   add('label[.7,9;Objectives must all be completed. Each round contains five registers.]label[.7,9.6;Completing on the last allowed register succeeds before timeout.]')
  end
  add('label[.7,10.5;'..esc(v.message or 'Draft autosaves. Finish text fields with Enter or BACK.')..']button[.7,11;14.5,.65;back;BACK TO WORKSHOP]')
  core.show_formspec(n,'shift_circuit:puzzle_settings',table.concat(f))
 end
 function U.handle(n,f)
  local d,p=config(n);local v=views[n]or {tab=1,round=1,mode='start'};views[n]=v;v.message=nil
  local function number(k,lo,hi)if f[k]then local x=tonumber(f[k]);if x and x==math.floor(x)and x>=lo and x<=hi then p[k]=x else v.message='Invalid '..k end end end
  number('hull',1,5);number('power',0,9);number('limit',0,999);number('order',1,9999)
  if f.hint then p.hint=f.hint:sub(1,180)end
  if f.description then p.description=f.description:sub(1,500)end
  if f.weapon and weapons[tonumber(f.weapon)]then p.weapon=weapons[tonumber(f.weapon)]end
  if f.start_facing then local dir=tonumber(f.start_facing);if dir and dir>=1 and dir<=4 then d.start.dir=dir-1 end end
  if f.no_reboot then p.no_reboot=f.no_reboot=='true'end
  for i=1,4 do if f['tab_'..i]then v.tab=i end end
  for _,k in ipairs({'start','checkpoint','target'})do if f['mode_'..k]then v.mode=k end end
  for _,k in ipairs(items)do if f['more_'..k]then p.equipment[k]=math.min(9,(p.equipment[k]or 0)+1)elseif f['less_'..k]then p.equipment[k]=math.max(0,(p.equipment[k]or 0)-1)end end
  if f.round then local nround=tonumber(f.round);if nround and nround==math.floor(nround)and nround>=1 and nround<=999 then v.round=nround else v.message='Round must be 1-999'end end
  local handkey=tostring(v.round)
  if f.random_hand then p.hands[handkey]=nil end
  for _,k in ipairs(cards)do if f['card_'..k]then p.hands[handkey]=p.hands[handkey]or {};local a=p.hands[handkey];if #a<12 then a[#a+1]=k end end end
  for i=1,12 do if f['remove_'..i]and p.hands[handkey]then table.remove(p.hands[handkey],i)end end
  local function toggle(list,key)local found;for i,k in ipairs(list)do if k==key then found=i end end;if found then table.remove(list,found)else list[#list+1]=key end end
  if f.clear_objectives then p.targets={};p.checkpoints={}end
  for key in pairs(f)do local x,z=key:match('^at_(%d+)_(%d+)$');if x then x,z=tonumber(x),tonumber(z);local k=x..','..z;local t=d.board[k]
   if t then if v.mode=='start'and t.kind=='checkpoint'then d.start={x=x,z=z,dir=d.start.dir};for i=#p.checkpoints,1,-1 do if p.checkpoints[i]==k then table.remove(p.checkpoints,i)end end
   elseif v.mode=='checkpoint'and t.kind=='checkpoint'and not (d.start.x==x and d.start.z==z)then toggle(p.checkpoints,k)
   elseif v.mode=='target'then if (d.crates or {})[k]then toggle(p.targets,'crate:'..k)elseif (d.enemies or {})[k]then toggle(p.targets,'obstacle:'..k)else v.message='Choose a crate or enemy'end
   else v.message='Choose a checkpoint candidate'end end
  end end
  draft(n).locked=true;save(n)
  if f.back or f.quit then draw(n);back(n)else U.open(n)end
 end
 return U
end
