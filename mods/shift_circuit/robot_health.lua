-- Observer-matched billboards follow each displayed robot, including owner views.
return function(spawn,Net)
 Net=Net or {properties=function(o,p)Net.properties(o,p)end}
 local H={}
 function H.cycle(b)
  if not b.scripted or b.kind~='ram_bot' or b.down then return nil end
  if b.winding then return 'wind','WIND UP / Next register: charge up to 3 squares' end
  if b.last_action=='CHARGE'then return 'charge','CHARGE / Next register: watch for a robot ahead' end
  return 'watch','WATCH / Robot ahead triggers wind-up, then charge next register'
 end
 function H.step(e)
  local actor=e.health_actor;local p=actor and actor:get_pos()
  if not p then e.object:remove();return end
  local a=actor:get_luaentity();local b=e.health_bot
  local visible=b and not b.finished and not a.fallen and (not b.crate or (b.kind=='loot'and not b.down))
  local maximum=math.max(1,math.min(9,math.floor(b.crate and 3 or b.max_hp or 5)))
  local hp=b.down and 0 or math.max(0,math.min(maximum,math.ceil(b.hp or 0)))
  local scale=a.display_scale or 1;local width=b.crate and .85 or (scale<1 and .8 or 1.15)
  local cycle=H.cycle(b)
  local key=maximum..':'..hp..':'..tostring(visible)..':'..width..':'..tostring(cycle)
  if key~=e.health_key then
   local texture=b.crate and ('sc_crate_health_'..hp..'.png')or ('sc_robot_health_'..maximum..'_'..hp..'.png')
   if cycle then texture='[combine:46x28:0,0='..texture..':0,12=sc_ram_cycle_'..cycle..'.png'end
   e.health_key=key;Net.properties(e.object,{is_visible=visible,visual_size={x=width,y=width*(cycle and 28 or 10)/46},textures={texture}})
  end
  Net.move(e.object,{x=p.x,y=p.y+(b.crate and 1.05 or 1.95)*scale,z=p.z})
 end
 function H.sync(b,actor)
  if not actor then return end
  local a=actor:get_luaentity();local o=a.health_bar
  if not o or not o:get_pos()then
   o=spawn('tile',actor:get_pos(),{visual='sprite',textures={'sc_robot_health_5_5.png'},visual_size={x=1.15,y=.25},pointable=false,glow=8,use_texture_alpha=true,nametag=''});a.health_bar=o
  end
  local e=o:get_luaentity();e.health_actor=actor;e.health_bot=b
  if actor.get_observers and o.set_observers then o:set_observers(actor:get_observers())end
  H.step(e)
 end
 return H
end
