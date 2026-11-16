return function(core,room_for,leave,review)
 local MenuUI=dofile(core.get_modpath('shift_circuit')..'/menu_ui.lua');core=MenuUI.wrap(core)
 local Lab={};local scenarios={{'weapons','RAY WEAPONS / TARGET AND WALL'},{'remote','REMOTE CONTROL / FUTURE REGISTERS'},{'arm','MECHANICAL ARM / REACH & RETRACT'},{'armor','CRUSHER / TITANIUM AND MEMORY'},{'spawners','POWERUP SPAWN SCHEDULES'},{'factories','FACTORIES / SUPPLY LINES'}}
 function Lab.open(name)
  local r=room_for(name);if not r or r.solo_mode~='test'or not core.get_player_privs(name).server then return end
  local f={'formspec_version[6]size[14,10]background[0,0;14,10;sc_setup_background.png]style_type[button;bgimg=sc_menu_button.png;bgimg_pressed=sc_menu_button_pressed.png;border=false]label[.7,.6;ADMIN / EQUIPMENT TEST LAB]'}
  for i,s in ipairs(scenarios)do f[#f+1]=('button[%s,%s;6.1,1;%s;%s]'):format(.7+(i-1)%2*6.5,1.4+math.floor((i-1)/2)*1.45,s[1],s[2]:gsub(' / ','\n'))end
  f[#f+1]='label[.8,6.3;Choose a scene. Use I for your dashboard. Queue cards and commit to test.]button[.7,7;6,.8;refill;REFILL HULL / POWER / PARTS]button[7.1,7;6.2,.8;resume;RETURN TO TEST]button[.7,8.2;6,.8;review;REVIEW SUBMISSIONS]button[7.1,8.2;6.2,.8;leave;LEAVE TEST LAB]'
  core.show_formspec(name,'shift_circuit:test_lab',table.concat(f))
 end
 function Lab.begin(r)r.api.lab(r.host,'weapons');Lab.open(r.host)end
 core.register_on_player_receive_fields(function(p,form,f)
  if form~='shift_circuit:test_lab'then return end;local n=p:get_player_name();local r=room_for(n)
  if not r or r.solo_mode~='test'or not core.get_player_privs(n).server then return end
  if f.review and review then review(n);return end
  if f.leave then leave(n);return end
  for _,s in ipairs(scenarios)do if f[s[1]]then r.api.lab(n,s[1]);core.close_formspec(n,form);return end end
  if f.refill then r.api.lab_refill(n)end
  if f.resume then core.close_formspec(n,form)else Lab.open(n)end
 end)
 return Lab
end
