return function(core,R)
 local MenuUI=dofile(core.get_modpath('shift_circuit')..'/menu_ui.lua');core=MenuUI.wrap(core)
 local U={};local weapons={'green_laser','double_laser','triple_laser','emp_generator','remote_control','tractor_beam','repulsor_beam'}
 local function aims(b)
  local values,labels={0},{'Front'}
  if (b.parts.turret_gearbox or 0)>0 then values={0,2,3,1};labels={'Front','Back','Left','Right'}end
  if (b.parts.thermal_camera or 0)>0 then values[#values+1]=4;labels[#labels+1]='Automatic'end
  return values,labels
 end
 local equipment={
  {'reset_button','Reset Button','Redraw hand / clears program.','consume'},
  {'electromagnetic_brake','Electromagnetic Brake','Resists pushes and pull beams.','toggle'},
  {'battering_ram','Battering Ram','Pushes deal 2 hull damage.','passive','sc_editor_30.png'},
  {'thermal_camera','Thermal Camera','Unlocks Automatic aim.','passive'},
  {'blueprint_archive','Blueprint Archive','Keep one item on reboot.','archive'},
  {'blink','Blink','Consumed on successful jump.','passive','sc_cmd_BLINK.png'},
  {'range','Extended Range','Adds 5 squares per copy.','passive','sc_cmd_PULSE.png'},
  {'cache','Command Cache','More cards / up to +3.','passive','sc_card_STEP.png'},
  {'mechanical_arm','Mechanical Arm','Reaches items and flags.','passive'},
  {'turret_gearbox','Aim Gearbox','Unlocks relative aiming.','passive'},
  {'hard_disk','Hard Disk','E keeps a command card.','passive'},
  {'holographic_memory','Holo Memory','Reboot here / excludes pits.','toggle'},
  {'gyro_stabilizer','Gyro Stabilizer','Skip forced turns this round.','toggle'},
  {'electroshield','Electroshield','Absorb hits for 1 power each.','toggle'},
  {'titanium_hull','Titanium Hull','Blocks one crush; breaks.','passive'}}
 local descriptions={green_laser='1 damage / no power cost',double_laser='2 damage / no power cost',triple_laser='3 damage / 1 power per hit',emp_generator='Disables / 2 power on hit',remote_control='Copies commands / 1 power on hit',tractor_beam='Pulls one square / no power cost',repulsor_beam='Pushes one square / no power cost'}
 local details={
  reset_button='Use during planning to redraw your movement hand. Clears queued commands and Hard Disk reservations. Keeps your blue direction and Blink card. Consumes one Reset Button. Unavailable for fixed puzzle hands.',
  electromagnetic_brake='While enabled, blocks robot pushes, pushers and tractor/repulsor beams. Commands and conveyors still move you. No power cost. Extra copies do not increase resistance.',
  battering_ram='Successful pushes deal 2 hull damage to the directly pushed robot. Blocked pushes do no damage. Additional copies do not increase damage.',
  thermal_camera='Automatic aim updates before each weapon phase. Selects the nearest visible enemy in range on a row or column. Walls and robots block sight. Always available in the aim selector; no separate toggle. Requires no Aim Gearbox. Falls back to Front when no target is available.',
  blueprint_archive='Randomly preserves one owned item by default. Choose a specific item to restore on respawn. Saves one copy only. Everything else, including this archive, is lost unless the archive itself is selected.',
  blink='Grants exactly one Blink card and one successful jump each round. Jump two squares over the middle square for 1 power. Landing must be safe and unblocked. Each successful jump consumes one collected Blink. At most one jump per round; unused copies remain. The card cannot be saved with a Hard Disk.',
  range='Always active. Each copy adds 5 squares of weapon range, with no power cost. Copies stack. Walls and robots still stop rays.',
  cache='Always active. Each copy adds two movement cards to your hand, up to three bonus cards. Cards must still be chosen and committed.',
  mechanical_arm='Each copy reaches one orthogonally adjacent pickup per register, up to four. Reaches across walls and also visits the next adjacent checkpoint. Always active; no power cost.',
  turret_gearbox='Always active. Unlocks Front, Back, Left and Right aiming for your loaded weapon. Direction stays relative to the robot as it turns. No power cost.',
  hard_disk='Always active. Press E on a command card (including Wait) to keep it next round. One reservation per disk, within the normal draw allowance. Blink cannot be retained.',
  holographic_memory='Consumes one copy on destruction to reboot on that square at round end. Does not save pit falls. Toggleable; no power cost.',
  gyro_stabilizer='Enable for this round to ignore conveyor turns and rotators. Programmed turns still work. Switches off at the next deal. No power cost.',
  electroshield='While enabled, spends 1 power per incoming damage point to protect hull. Ordinary shields are used first. Does not stop crushing, Remote Control or beam displacement.',
  titanium_hull='Automatically consumes one copy to survive a crusher strike with no hull damage. The plating breaks. No power cost.'}
 local function owned(b)
  local choices={};for _,k in ipairs(weapons)do if k=='green_laser'or k==b.weapon or (b.parts[k]or 0)>0 then choices[#choices+1]=k end end;return choices
 end
 function U.formspec(b,phase,note,goal)
  local esc=core.formspec_escape;local f={'formspec_version[6]size[16,11.3]bgcolor[#09131fee;true]background[0,0;16,11.3;sc_dashboard_bg.png]style_type[button;bgimg=sc_menu_button.png;bgimg_pressed=sc_menu_button_pressed.png;border=false]label[.6,.45;ROBOT / DASHBOARD]'}
  local function add(t)f[#f+1]=t end
  if not b then add('label[.8,2;SPECTATING / Watch the racers on the board.]button[.6,10;6,.8;room;MATCH MENU]button_exit[9.8,10;5.6,.8;close;RETURN TO BOARD]');return MenuUI.decorate(table.concat(f))end
  R.normalize(b);local editable=phase=='program'and not b.ready
  add('label[7.8,.45;'..(b.down and 'DESTROYED / reboot after round'or (editable and 'PLANNING / changes save immediately'or 'LOCKED / changes next round'))..']')
  local stats={{'HULL',math.max(0,b.hp or 0)..' / '..(b.max_hp or 5),'hull',math.max(0,b.hp or 0)},{'POWER',(b.energy or 0)..' / 9','energy',b.energy or 0},{'SHIELD',(b.shield or 0)..' charges','shield',b.shield or 0},{'HAND',(b.allowance or 9)..' cards','hand',b.allowance or 9}}
  for i,v in ipairs(stats)do local x=.6+(i-1)*3.8;add(('image[%s,1;3.5,1.25;sc_dashboard_stat.png]label[%s,1.23;%s]label[%s,1.6;%s]image[%s,1.82;3,.32;sc_dashboard_%s_%d.png]'):format(x,x+.15,v[1],x+.15,v[2],x+.15,v[3],v[4]))end
  add('tooltip[.6,.9;3.5,1.3;Each missing hull point removes one card from the next deal. Repair restores that choice on the following deal.]')
  add('tooltip[12,.9;3.5,1.3;'..esc('9 base + '..(b.draw_bonus or 0)..' bonus - '..(b.hull_penalty or 0)..' hull damage - '..(b.last_penalty or 0)..' disruption at the last deal. Always at least 5 cards.')..']')
  add('image[.6,2.6;5,6.6;sc_dashboard_weapon.png]label[.85,2.9;LOADED WEAPON]image[2.25,3.3;1.65,1.65;sc_part_'..b.weapon..'.png]')
  add('tooltip[2.25,3.3;1.65,1.65;'..esc(R.weapons[b.weapon].title..' / '..descriptions[b.weapon]..'. Activates from round 2 and fires each register; walls block the ray.'..(b.weapon=='emp_generator'and ' Skips every remaining command this round. Resumes next round.'or '')..(b.weapon=='remote_control'and ' Once per round; replaces unexecuted commands only.'or ''))..']')
  local choices=owned(b);local labels={};local selected=1;for i,k in ipairs(choices)do labels[i]=R.weapons[k].title;if k==b.weapon then selected=i end end
  if editable then add('dropdown[.9,5.1;4.4,.65;weapon;'..table.concat(labels,',')..';'..selected..';true]')else add('label[.9,5.4;'..esc(R.weapons[b.weapon].title)..' / LOCKED]')end
  add('label[.9,5.95;'..esc(descriptions[b.weapon])..']')
  local aim_values,aim_labels=aims(b);local aim=1;for i,v in ipairs(aim_values)do if v==b.aim_offset then aim=i end end
  add('label[.9,6.5;FIRE DIRECTION]')
  if #aim_values>1 and editable then
   add('dropdown[.9,6.8;4.4,.65;aim;'..table.concat(aim_labels,',')..';'..aim..';true]label[.9,7.7;Turns with your robot]')
  else
   local facing=b.aim_offset==4 and 'Automatic'or (b.parts.turret_gearbox or 0)>0 and ({'Front','Right','Back','Left'})[(b.aim_offset or 0)+1]or 'Front'
   add('box[.9,6.8;4.4,.65;#17303b]label[1.1,7.13;'..facing..' / LOCKED]label[.9,7.7;'..((b.parts.turret_gearbox or 0)>0 and 'Changes unlock next round'or 'Aim Gearbox unlocks direction')..']')
  end
  add('label[.9,8.2;SPARE WEAPONS]')
  local spare=0;for _,kind in ipairs(weapons)do local count=b.parts[kind]or 0;if count>0 and kind~=b.weapon and kind~='green_laser' then local x=.9+spare*.7;spare=spare+1
   add(('image[%s,8.5;.5,.5;sc_part_%s.png]tooltip[%s,8.45;.75,.75;%s]'):format(x,kind,x,esc(R.weapons[kind].title..' / '..descriptions[kind]..'. Choose it above to load it immediately.'..(kind=='remote_control'and ' Once per round; replaces unexecuted commands.'or ''))))
  end end;if spare==0 then add('label[.9,8.65;No spare weapons collected.]')end
  add('label[6,2.9;EQUIPMENT]')
  local owned=0;for _,entry in ipairs(equipment)do if (b.parts[entry[1]]or 0)>0 then owned=owned+1 end end
  local opening,closing=MenuUI.scroll(6,3.3,9.1,5.9,'equipment_scroll',math.max(0,owned*1.4-.12));add(opening)
  local index=0
  for _,entry in ipairs(equipment)do local k,title,description,mode,icon=entry[1],entry[2],entry[3],entry[4],entry[5];local count=b.parts[k]or 0
   if count>0 then
    local x=0;local y=index*1.4;index=index+1
    add(('image[%s,%s;9.1,1.28;sc_dashboard_equipment.png]image[%s,%s;.65,.65;%s]label[%s,%s;%s]'):format(x,y,x+.18,y+.3,icon or ('sc_part_'..k..'.png'),x+1.02,y+.33,esc(title..(count>1 and ' x'..count or ''))))
    add(('label[%s,%s;%s]'):format(x+1.02,y+.85,esc(description)))
    add(('tooltip[%s,%s;9.1,1.28;%s]'):format(x,y,esc(title..' / '..count..' collected. '..details[k]..(R.unique_parts[k]and ' Does not stack.'or ''))))
    if k=='blink'then mode=(b.blink_left or 0)>0 and '1 jump ready'or 'Next round'
    elseif k=='range'then mode='Range: '..b.range..' squares'
    elseif k=='cache'then mode='+'..b.draw_bonus..' cards'
    elseif mode=='passive'then mode=k=='hard_disk'and count..' card reservations'or 'Always active'end
    if mode=='consume' then
     if editable then add(('button[%s,%s;2.85,.65;use_reset;RESET HAND]tooltip[use_reset;%s]'):format(x+6.05,y+.38,esc(details.reset_button)))else add(('label[%s,%s;Planning only]'):format(x+6.05,y+.65))end
    elseif mode=='archive' then
     local items=R.archive_choices(b);local labels={'Random item'};local selection=1
     for i,item in ipairs(items)do labels[#labels+1]=R.weapons[item]and R.weapons[item].title or (item:gsub('_',' '):gsub('(%a)([%w]*)',function(a,b)return a:upper()..b end));if item==b.archive_item then selection=i+1 end end
     if editable then add(('dropdown[%s,%s;2.85,.6;archive_item;%s;%d;true]'):format(x+6.05,y+.38,esc(table.concat(labels,'|')):gsub('|',','),selection))else add(('label[%s,%s;%s]'):format(x+6.05,y+.68,esc((b.archive_item or 'Random item'):gsub('_',' '))))end
    elseif mode=='toggle'and editable then local enabled=k=='gyro_stabilizer'and R.gyro(b)or (k~='gyro_stabilizer'and not (b.enabled and b.enabled[k]==false));add(('checkbox[%s,%s;enable_%s;%s;%s]'):format(x+6.05,y+.65,k,k=='gyro_stabilizer'and 'Enable this round'or 'Enabled',tostring(enabled==true)))
    else if mode=='toggle'then mode=(k=='gyro_stabilizer'and R.gyro(b)or (k~='gyro_stabilizer'and not (b.enabled and b.enabled[k]==false)))and 'ENABLED'or 'DISABLED'end;add(('label[%s,%s;%s]'):format(x+6.05,y+.65,esc(mode)))end
   end
  end
  if index==0 then add('image[1.6,.5;5.6,3.2;sc_dashboard_empty.png]label[1.3,4;Collect equipment on the board.]')end
  local goal_text=note or ('NEXT: '..(goal or (b.down and 'Reboot after the round'or (b.finished and 'Route complete'or 'Checkpoint '..(b.next or 1)))))
  goal_text=goal_text:gsub('&','&amp;'):gsub('<','&lt;'):gsub('>','&gt;')
  add(closing..'box[.6,9.4;14.8,.025;#49777d]hypertext[.8,9.5;14.2,.45;next_goal;'..esc('<style color=#adc4cd size=15>'..goal_text)..']')
  if editable then add('label[.8,10.4;Changes save automatically.]')else add('label[.8,10.4;Changes unlock next round.]')end
  add('button[6,10;4.2,.8;room;MATCH MENU]button_exit[10.5,10;4.9,.8;close;RETURN TO BOARD]')
  return MenuUI.decorate(table.concat(f))
 end
 function U.changed(f)
  if f.use_reset or f.weapon or f.aim or f.apply or f.archive_item then return true end
  for _,entry in ipairs(equipment)do if f['enable_'..entry[1]]~=nil then return true end end
  return false
 end
 function U.show(p,b,phase,note)core.show_formspec(p:get_player_name(),'shift_circuit:loadout',U.formspec(b,phase,note))end
 function U.apply(b,f)
  R.normalize(b);local aim_values=aims(b);local choices=owned(b);local weapon=choices[tonumber(f.weapon)or 0]or b.weapon;local aim=aim_values[tonumber(f.aim)or 0]or b.aim_offset
  local ok,note=R.loadout(b,weapon,aim);if not ok then return false,note end
  if f.archive_item and (b.parts.blueprint_archive or 0)>0 then local choices=R.archive_choices(b);b.archive_item=choices[(tonumber(f.archive_item)or 1)-1]end
  b.enabled=b.enabled or {};for _,entry in ipairs(equipment)do local key=entry[1];if entry[4]=='toggle'and (b.parts[key]or 0)>0 and f['enable_'..key]~=nil then b.enabled[key]=f['enable_'..key]=='true'end end
  return true,'Saved / '..R.weapons[b.weapon].title
 end
 return U
end
